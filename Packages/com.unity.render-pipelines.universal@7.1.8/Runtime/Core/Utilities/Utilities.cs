using System;

namespace UnityEngine.Rendering.Universal.Internal
{
    public static class ShaderIDs
    {
        public static readonly int _ViewProjMatrix = Shader.PropertyToID("_ViewProjMatrix");
    }
    public class Utilities
    {

        public static void SetViewProjectionMatrices(CommandBuffer cmd, Matrix4x4 view, Matrix4x4 proj, bool renderToTexture = true)
        {
            cmd.SetViewProjectionMatrices(view, proj);
            cmd.SetGlobalMatrix(ShaderIDs._ViewProjMatrix, GL.GetGPUProjectionMatrix(proj, renderToTexture) * view);
        }
    }
}