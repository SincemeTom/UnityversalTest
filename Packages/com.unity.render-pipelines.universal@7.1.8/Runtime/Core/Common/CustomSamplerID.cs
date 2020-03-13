
using UnityEngine.Profiling;

namespace UnityEngine.Rendering.GRenderPipeline
{
    public enum CustomSamplerID
    {
        GRenderPipelineRender,
        CullResultsCull,
        DepthPrepass,
        TrabsparentDepthPrepass,
        GBuffer,
        ClearColorBuffer,
        ClearBuffers,
        ClearGBuffer,
        ClearDepthStencil,
        BlitToFinalRT,
        ForwardPass,
        CollectShadows,
        CopyDepthForSceneView,
        PrepareLightsForGPU,
        DrawShadowRT,
        PushGlobalParameters,
        RenderShadows,
        DeferredShadows,
        DrawDirectionalShadowmap,
        DrawDirectionalLightTransmissionMap,
        DrawCharacterShadow,
        DeferredReflections,
        RenderDeferredSSS,
        RenderDeferredDirectionalLighting,
        TiledDeferredLighting,
        CameraVelocity,
        ObjectsVelocity,
        BuildLightList,
        PostProcess,
        OpaqueFog,
        SkyBox,
        ClearAdditionalBuffer,
        CopyDepthBuffer,
        RenderAdditionalLight,
        RenderAdditionalLightSSS,
        DrawAdditionalLightShadowMap,
        RenderSSAO,
        RenderGTAO,

        RenderCloud,
        RenderUltraSky,
        RenderSeaOfCloud,
        ClearScreenShadowBuffer,
        GrabOpqaueTexture,
        RenderWater,
        VolumetricFog,
        RenderVoluemLighting,
        RenderAtmosphericScattering,
        RenderCustomSkyBox,
        DrawShadowAtlas,
        CleanShaowmapAtlas,
        RenderDebug,
        ColorPyramid,
        DepthPyramid,

        SSR,
        SsrTracing,
        SsrReprojection,

        // Profile sampler for tile pass
        TPPrepareLightsForGPU,
        TPPushGlobalParameters,

        // Misc
        VolumeUpdate,

        //SSS
        SubsurfaceScattering,
        HTileForSSS,
        ClearSSSFilteringTarget,

        Max
    }
    public static class CustomSamplerExtension
    {
        static CustomSampler[] s_Samplers;
        public static CustomSampler GetSampler(this CustomSamplerID samplerID)
        {
            if(s_Samplers == null)
            {
                s_Samplers = new CustomSampler[(int)CustomSamplerID.Max];
                for(int i = 0; i < (int) CustomSamplerID.Max; i++)
                {
                    var id = (CustomSamplerID)i;
                    s_Samplers[i] = CustomSampler.Create("C#_" + id);
                }
            }
            return s_Samplers[(int)samplerID];
        }
        
    }

}