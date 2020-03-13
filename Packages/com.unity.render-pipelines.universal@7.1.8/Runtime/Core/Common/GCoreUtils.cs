namespace UnityEngine.Rendering {

    public delegate void Action<T1, T2, T3, T4, T5>(T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5);

    public static class GCoreUtils
    {
        public static string GetGRenderPipelinePath() {
#if DRAGON_SLAY_ENGINE
            return "Assets/Module/RenderSystem/com.sdgames.grenderpipeline/GRenderPipeline/";
#else
            return "Packages/com.sdgames.grenderpipeline/GRenderPipeline/";
#endif
        }

        public static bool isPreviewOrReflectionCamera(Camera camera) {
            return camera.cameraType == CameraType.Preview || camera.cameraType == CameraType.Reflection;
        }

        public static string GetRenderTargetAutoName(int width, int height, RenderTextureFormat format, string name = "", bool mips = false, bool enableMSAA = false, MSAASamples msaaSamples = MSAASamples.None, int CameraGroup = 0, bool bindMSTexture = false)
        {
            string str;
            if (enableMSAA)
            {
                 str = string.Format("{0}x{1}_{2}{3}_{4}", width, height, format, mips ? "_Mips" : "", msaaSamples.ToString());
            }
            else
            {
                 str = string.Format("{0}x{1}_{2}{3}", width, height, format, mips ? "_Mips" : "");
            }
            if (bindMSTexture)
            {
                str += "_bindMsTexture";
            }
            str += "_CameraGroup" + CameraGroup.ToString();
            str = string.Format("{0}_{1}", name == "" ? "Texture" : name, str);

            return str;
        }

        public static string GetTextureAutoName(int width, int height, TextureFormat format,TextureDimension dim = TextureDimension.None, string name = "", bool mips = false, int depth = 0, bool bindMSTexture = false)
        {
            string str;
            if (depth == 0)
                str = string.Format("{0}x{1}_{2}{3}", width, height, format, mips ? "_Mips" : "");
            else
                str = string.Format("{0}x{1}x{2}_{3}{4}", width, height,depth, format, mips ? "_Mips" : "");
            str = string.Format("{0}_{1}_{2}", name == "" ? "Texture" : name, (dim == TextureDimension.None)? "" : dim.ToString(), str);

            if (bindMSTexture)
            {
                str += "_bindMsTexture";
            }
            return str;
        }

        public static bool IsSupportMultipleRenderTarget()
        {
            return SystemInfo.graphicsDeviceType == GraphicsDeviceType.Direct3D11 || SystemInfo.graphicsDeviceType == GraphicsDeviceType.OpenGLCore ||
                SystemInfo.graphicsDeviceType == GraphicsDeviceType.OpenGLES3 || SystemInfo.graphicsDeviceType == GraphicsDeviceType.Metal || SystemInfo.graphicsDeviceType == GraphicsDeviceType.Vulkan;
        }
    }

}

