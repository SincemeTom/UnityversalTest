using System;
using UnityEngine.Scripting.APIUpdating;

namespace UnityEngine.Rendering.LWRP
{
    [Obsolete("LWRP -> Universal (UnityUpgradable) -> UnityEngine.Rendering.Universal.UniversalAdditionalLightData", true)]
    public class LWRPAdditionalLightData
    {
    }
}


namespace UnityEngine.Rendering.Universal
{
    public enum RenderingLayerMask
    {
        LightLayer1 = 1 << 0,
        LightLayer2 = 1 << 1,
        LightLayer3 = 1 << 2,
        LightLayer4 = 1 << 3,
        LightLayer5 = 1 << 4,
        LightLayer6 = 1 << 5,
        LightLayer7 = 1 << 6,
        LightLayer8 = 1 << 7,
        LightLayer9 = 1 << 8,
        LightLayer10 = 1 << 9,
        LightLayer11 = 1 << 10,
        LightLayer12 = 1 << 11,
        LightLayer13 = 1 << 12,
        LightLayer14 = 1 << 13,
        LightLayer15 = 1 << 14,
        LightLayer16 = 1 << 15,
        LightLayer17 = 1 << 16,
        LightLayer18 = 1 << 17,
        LightLayer19 = 1 << 18,
        LightLayer20 = 1 << 19,
        LightLayer21 = 1 << 20,
        LightLayer22 = 1 << 21,
        LightLayer23 = 1 << 22,
        LightLayer24 = 1 << 23,
        LightLayer25 = 1 << 24,
        LightLayer26 = 1 << 25,
        LightLayer27 = 1 << 26,
        LightLayer28 = 1 << 27,
        LightLayer29 = 1 << 28,
        LightLayer30 = 1 << 29,
        LightLayer31 = 1 << 30,
        LightLayer32 = 1 << 31,
    }

    [DisallowMultipleComponent]
    [RequireComponent(typeof(Light))]
    public class UniversalAdditionalLightData : MonoBehaviour
    {


        [Tooltip("Controls the usage of pipeline settings.")]
        [SerializeField] bool m_UsePipelineSettings = true;

        public bool usePipelineSettings
        {
            get { return m_UsePipelineSettings; }
            set { m_UsePipelineSettings = value; }
        }

    }
}
