using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;



namespace UnityEngine.Rendering.Universal.Internal
{
    public class CharacterShadowCasterPass : ScriptableRenderPass
    {
        public static class CharacterShadowConstantBuffer
        {
            public static int _CharacterShadowMatrix;
            public static int _CharacterShadowmapSize;
            public static int _CharacterShadowFilterWidth;
        }

        private const string m_ProfilerTag = "Character Shadowmap";
        public CharacterShadow characterShadow;

        private int m_ShadowmapWidth;
        private int m_ShadowmapHeight;
        const int k_ShadowmapBufferBits = 16;
        private RenderTargetHandle m_CharacterShadowmap;

        private RenderTexture m_CharacterShadowmapTexture;
        private CullingResults m_CharacterShadowCullResult;

        FilteringSettings m_FilteringSettings;
        RenderStateBlock m_RenderStateBlock;
        List<ShaderTagId> m_ShaderTagIdList = new List<ShaderTagId>();

        public CharacterShadowCasterPass(RenderPassEvent evt, uint renderingLayerMask)
        {
            renderPassEvent = evt;

            m_ShaderTagIdList.Add(new ShaderTagId("ShadowCaster"));

            renderPassEvent = evt;
            m_FilteringSettings = new FilteringSettings(RenderQueueRange.all, -1, renderingLayerMask);
            m_RenderStateBlock = new RenderStateBlock(RenderStateMask.Nothing);

            CharacterShadowConstantBuffer._CharacterShadowMatrix = Shader.PropertyToID("_CharacterShadowMatrix");
            CharacterShadowConstantBuffer._CharacterShadowmapSize = Shader.PropertyToID("_CharacterShadowmapSize");
            CharacterShadowConstantBuffer._CharacterShadowFilterWidth = Shader.PropertyToID("_CharacterShadowFilterWidth");

            m_CharacterShadowmap.Init("_CharacterShadowMap");
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            base.Configure(cmd, cameraTextureDescriptor);
            if(m_CharacterShadowmapTexture == null)
            {
                m_CharacterShadowmapTexture = ShadowUtils.GetTemporaryShadowTexture(m_ShadowmapWidth,m_ShadowmapHeight, k_ShadowmapBufferBits);
                m_CharacterShadowmapTexture.name = "CharacterShadowmapTexture";
            }
            ConfigureTarget(new RenderTargetIdentifier(m_CharacterShadowmapTexture));
            ConfigureClear(ClearFlag.All, Color.black);
        }


        public bool Setup(ref RenderingData renderingData, CharacterShadow InCharacterShadow)
        {
            if (InCharacterShadow == null)
                return false;
            if (!renderingData.shadowData.supportsCharacterShadows)
                return false;

            int shadowLightIndex = renderingData.lightData.mainLightIndex;
            if (shadowLightIndex == -1)
                return false;

            VisibleLight shadowLight = renderingData.lightData.visibleLights[shadowLightIndex];
            Light light = shadowLight.light;
            if (light.shadows == LightShadows.None)
                return false;

            if (shadowLight.lightType != LightType.Directional)
            {
                Debug.LogWarning("Only directional lights are supported character shadow.");
                return false;
            }

            Clear();

            characterShadow = InCharacterShadow;
            m_ShadowmapWidth = renderingData.shadowData.characterShadowmapWidth;
            m_ShadowmapHeight = renderingData.shadowData.characterShadowmapHeight;
            return true;
        }


        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
            using (new ProfilingSample(cmd, m_ProfilerTag))
            {
                bool bEnableCharacterShadow = RenderCharacterShadowmap(context, cmd, ref renderingData);
                CoreUtils.SetKeyword(cmd, ShaderKeywordStrings.CharacterShadowStr, bEnableCharacterShadow);
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);


        }
        public override void FrameCleanup(CommandBuffer cmd) {
            base.FrameCleanup(cmd);
            characterShadow = null;

            if (cmd == null)
                throw new ArgumentNullException("cmd");

            if (m_CharacterShadowmapTexture)
            {
                RenderTexture.ReleaseTemporary(m_CharacterShadowmapTexture);
                m_CharacterShadowmapTexture = null;
            }
        }

        public void Cleanup() {
            if (m_CharacterShadowmapTexture)
                RenderTexture.ReleaseTemporary(m_CharacterShadowmapTexture);
            m_CharacterShadowmapTexture = null;
        }
        void Clear()
        {
            m_CharacterShadowmapTexture = null;
        }

        public bool RenderCharacterShadowmap(ScriptableRenderContext context, CommandBuffer cmd, ref RenderingData renderingData) {
            
            Camera camera = renderingData.cameraData.camera;

            int shadowLightIndex = renderingData.lightData.mainLightIndex;
            if (shadowLightIndex == -1)
                return false;

            VisibleLight shadowLight = renderingData.lightData.visibleLights[shadowLightIndex];



            Light light = shadowLight.light;

            if (light == null || characterShadow == null) return false;

            Debug.Assert(light.type == LightType.Directional);

            if (light.shadows == LightShadows.None)
                return false;

            bool renderShadow = characterShadow.UpdateFocus(light,camera);
            if (!renderShadow) return false;


            //using (new ProfilingSample(cmd, m_ProfilerTag))
            {
                //Culling
                ScriptableCullingParameters cullingParams;
                if (!camera.TryGetCullingParameters(out cullingParams))
                {
                    return false;
                }
                cullingParams.isOrthographic = true;
                cullingParams.cullingMatrix = characterShadow.ProjMatrix * characterShadow.ViewMatrix;
                cullingParams.origin = characterShadow.CameraCenter;
                cullingParams.cullingOptions = CullingOptions.ShadowCasters;
                //cullingParams.SetLayerCullingDistance
                Plane[] planes = GeometryUtility.CalculateFrustumPlanes(cullingParams.cullingMatrix);
                cullingParams.cullingPlaneCount = 6;
                for (int i = 0; i < planes.Length; ++i)
                {
                    cullingParams.SetCullingPlane(i, planes[i]);
                }
                m_CharacterShadowCullResult = context.Cull(ref cullingParams);

                
                float frusumSize = 2.0f / characterShadow.ProjMatrix.m00;
                const float kernelRadius = 2.5f;
                float m_texelSize = frusumSize / Mathf.Min(m_ShadowmapWidth, m_ShadowmapHeight);
                float m_depthBias =  -characterShadow.Bias * m_texelSize;
                float m_normalBias = -characterShadow.NormalBias * m_texelSize;
                if (light.shadows == LightShadows.Soft)
                {
                    m_depthBias *= kernelRadius;
                    m_normalBias *= kernelRadius;
                }
                //CoreUtils.SetKeyword(cmd, GRenderKeywords.AdditionalShadowStr, false);
                Vector3 lightDirection = -light.transform.forward;
                cmd.SetGlobalVector("_ShadowBias", new Vector4(m_depthBias, m_normalBias, m_texelSize * 1.4142135623730950488016887242097f, 0.0f));
                cmd.SetGlobalVector("_LightDirection", new Vector4(lightDirection.x, lightDirection.y, lightDirection.z, 0.0f));

                //CoreUtils.SetRenderTarget(cmd, m_CharacterShadowmapTexture, ClearFlag.Depth);


                Utilities.SetViewProjectionMatrices(cmd, characterShadow.ViewMatrix, characterShadow.ProjMatrix);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();


                var sortFlags = renderingData.cameraData.defaultOpaqueSortFlags;
                var drawSettings = CreateDrawingSettings(m_ShaderTagIdList, ref renderingData, sortFlags);


                FilteringSettings filterSettings = m_FilteringSettings;
                context.DrawRenderers(m_CharacterShadowCullResult, ref drawSettings, ref filterSettings);
                context.ExecuteCommandBuffer(cmd);

                //set shader params
                float width = m_ShadowmapWidth;
                float height = m_ShadowmapHeight;

                cmd.SetGlobalTexture(m_CharacterShadowmap.id, m_CharacterShadowmapTexture);
                cmd.SetGlobalMatrix(CharacterShadowConstantBuffer._CharacterShadowMatrix, characterShadow.ShadowMatrix);
                cmd.SetGlobalVector(CharacterShadowConstantBuffer._CharacterShadowmapSize, new Vector4(1 / width, 1 / height, width, height));
                cmd.SetGlobalVector(CharacterShadowConstantBuffer._CharacterShadowFilterWidth, characterShadow.GetFilterWidth(width, height));
            }

            return true;

        }
    }

}

