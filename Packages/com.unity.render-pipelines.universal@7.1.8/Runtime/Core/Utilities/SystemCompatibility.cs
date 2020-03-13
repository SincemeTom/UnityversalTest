namespace UnityEngine.Rendering.GRenderPipeline {
    public class SystemCompatibility {

        public static bool SupportTiledShading {
            get { return SystemInfo.supportsComputeShaders
                    && SystemInfo.graphicsDeviceType != GraphicsDeviceType.OpenGLCore &&
                //        !Application.isMobilePlatform &&
                        Application.platform != RuntimePlatform.WebGLPlayer;
                }
        }

        public static bool SupportComputeShader {
            get { return SystemInfo.supportsComputeShaders; }
        }

        public static RenderTextureFormat FORMAT_HDR {
            get => SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.RGB111110Float) ? RenderTextureFormat.RGB111110Float : RenderTextureFormat.ARGBHalf;
        }

        public static RenderTextureFormat FORMAT_ARGBHalf {
            get => SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBHalf) ? RenderTextureFormat.ARGBHalf : RenderTextureFormat.ARGB32;
        }

        public static RenderTextureFormat FORMAT_R8 {
            get => SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.R8) ? RenderTextureFormat.R8 : RenderTextureFormat.ARGB32;
        }

        public static RenderTextureFormat FORMAT_ARGB2101010 {
            get => SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGB2101010) ? RenderTextureFormat.ARGB2101010 : RenderTextureFormat.ARGB32;
        }
    }

}
