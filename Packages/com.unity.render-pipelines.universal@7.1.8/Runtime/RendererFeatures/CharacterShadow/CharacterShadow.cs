using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace UnityEngine.Rendering.Universal.Internal
{
    [ExecuteInEditMode]
    public class CharacterShadow : MonoBehaviour
    {
        public bool autoFocus;
        public bool autoCulling = true;
        public bool autoBias = true;
        public float nearBias = 1.0f;
        public float farBias = 5.0f;
        public float nearNormalBias = 1.0f;
        public float farNormalBias = 5.0f;
        public float autoFocusRadiusBias;
        public Transform target;
        public Vector3 offset;
        [Min(0.01f)]
        public float radius = 1f;
        [Min(0f)]
        public float near = 0.0f;
        [Min(0.1f)]
        public float far = 2.0f;
        public float fallbackFilterWidth = 2f;
        public float bias = 1.0f;
        public float normalBias = 1.0f;

        private float m_bias = 1.0f;
        private float m_normalbias = 1.0f;

        public Light MainLight;
        private Matrix4x4 m_viewMatrix;
        private Matrix4x4 m_projMatrix;
        private Matrix4x4 m_shadowMatrix;
        private Vector3 m_cameraCenter;

        public Matrix4x4 ViewMatrix { get { return m_viewMatrix; } set { m_viewMatrix = value; } }
        public Matrix4x4 ProjMatrix { get { return m_projMatrix; } set { m_projMatrix = value; } }
        public Matrix4x4 ShadowMatrix { get { return m_shadowMatrix; } set { m_shadowMatrix = value; } }
        public Vector3 CameraCenter { get { return m_cameraCenter; } set { m_cameraCenter = value; } }
        public float Bias { get { return autoBias ? m_bias : bias; } set { m_bias = value; } }
        public float NormalBias { get { return autoBias ? m_normalbias : normalBias; } set { m_normalbias = value; } }


        void Update() {
            if (target == null) return;
            AutoFocus();
        }
        private void OnEnable()
        {
            
        }
        private void OnDisable()
        {
            
        }
        private void AutoFocus() {
            if (!autoFocus) return;
            var targetPos = target.position + target.right * offset.x
                + target.up * offset.y + target.forward * offset.z;

            var self = GetComponent<Renderer>();
            var bounds = new Bounds(targetPos, Vector3.one * 0.1f);
            foreach (var r in GetComponentsInChildren<Renderer>())
                if (r != self)
                    bounds.Encapsulate(r.bounds);

            offset = bounds.center - target.position;
            radius = autoFocusRadiusBias + bounds.extents.magnitude;
        }
        public bool AutoUpdateMatrix(Light shadowLight, Camera camera)
        {
            if (target == null) return false;
            if (camera == null) return false;
            var targetPos = target.position + target.right * offset.x
                + target.up * offset.y + target.forward * offset.z;

            var lightDir = shadowLight.transform.forward;
            var lightOri = shadowLight.transform.rotation;

            float cosA = Mathf.Abs(Vector3.Dot(lightDir, camera.transform.forward));
            float distance = Vector3.Distance(camera.transform.position, targetPos);
            distance = Mathf.Max(distance, radius);

            float zfar = (distance + near + far) ;
            float top = Mathf.Tan(Mathf.Deg2Rad * camera.fieldOfView  * 0.5f) * distance;

            if (autoBias)
            {
                Bias = Mathf.Lerp(nearBias, farBias, distance / (distance + radius));
                NormalBias = Mathf.Lerp(nearNormalBias, farNormalBias, distance / (distance + radius));
            }
            float right = camera.aspect * top;
            float max = Mathf.Max(top, right);
           // max = Mathf.Max(max, radius);
            top = right = max;
            float bottom = -top;
            float left = -right;


            m_cameraCenter = targetPos - lightDir * radius;
            m_viewMatrix = GeometryUtils.CalculateWorldToCameraMatrixRHS(m_cameraCenter, lightOri);
            m_projMatrix = Matrix4x4.Ortho(left, right, bottom, top, near, zfar);

            m_shadowMatrix = GetShadowTransform(m_projMatrix, m_viewMatrix, 0);
            return true;
        }
        public bool UpdateFocus(Light shadowLight, Camera camera) {
            if (target == null) return false;
            if (camera == null) return false;

            if (autoCulling)
                return AutoUpdateMatrix(shadowLight, camera);
            var targetPos = target.position + target.right * offset.x
                + target.up * offset.y + target.forward * offset.z;

            var lightDir = shadowLight.transform.forward;
            var lightOri = shadowLight.transform.rotation;

            m_cameraCenter = targetPos - lightDir * radius;
            m_viewMatrix = GeometryUtils.CalculateWorldToCameraMatrixRHS(m_cameraCenter, lightOri);
            m_projMatrix = Matrix4x4.Ortho(-radius, radius, -radius, radius, near, far);

            m_shadowMatrix = GetShadowTransform(m_projMatrix, m_viewMatrix, 0);
            return true;
        }

        public Vector2 GetFilterWidth(float shadowMapWidth,float shadowMapHeight) {
            var relativeTexelSize = new Vector2(shadowMapWidth, shadowMapHeight) / 2048f;
            return new Vector2(1f / shadowMapWidth * relativeTexelSize.x, 1f / shadowMapHeight * relativeTexelSize.y) * fallbackFilterWidth;
        }

        private Matrix4x4 GetShadowTransform(Matrix4x4 proj, Matrix4x4 view, float depthBias) {
            if (SystemInfo.usesReversedZBuffer) {
                proj.m20 = -proj.m20;
                proj.m21 = -proj.m21;
                proj.m22 = -proj.m22;
                proj.m23 = -proj.m23;
            }

            Matrix4x4 worldToShadow = proj * view;

            var db = SystemInfo.usesReversedZBuffer ? depthBias : -depthBias;

            var textureScaleAndBias = Matrix4x4.identity;
            textureScaleAndBias.m00 = 0.5f;
            textureScaleAndBias.m11 = 0.5f;
            textureScaleAndBias.m22 = 0.5f;
            textureScaleAndBias.m03 = 0.5f;
            textureScaleAndBias.m23 = 0.5f;
            textureScaleAndBias.m13 = 0.5f + db;
            return textureScaleAndBias * worldToShadow;
        }

        void OnDrawGizmosSelected() {
            if (target == null)
                return;
            if (MainLight == null || MainLight.type != LightType.Directional)
                return;
            Gizmos.color = autoFocus ? Color.cyan : Color.green;

            var p = target.position + target.right * offset.x + target.up * offset.y + target.forward * offset.z;
            Gizmos.DrawWireSphere(p, radius + (autoFocus ? autoFocusRadiusBias : 0f));


            Light light = MainLight;
            if(light != null) {
                Matrix4x4 rotationMatrix = Matrix4x4.TRS(m_cameraCenter + light.transform.forward * radius, light.transform.rotation, Vector3.one);
                Gizmos.matrix = rotationMatrix;
                Gizmos.DrawWireCube(Vector3.zero, new Vector3(radius * 2, radius * 2, radius * 2));
                Gizmos.matrix = Matrix4x4.identity;
            }

        }
    }

}
