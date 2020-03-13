using System;
using UnityEngine.Rendering;
namespace UnityEngine.Rendering.GRenderPipeline
{
    public class GRenderQueue
    {
        public enum Priority
        {
            Background = RenderQueue.Background,

            Terrain = RenderQueue.Geometry - 200,

            Opaque = RenderQueue.Geometry,

            OpaqueAlphaTest  = RenderQueue.AlphaTest,

            OpaqueLast = RenderQueue.GeometryLast,

            Hair = RenderQueue.GeometryLast + 10,
            
            Transparent = RenderQueue.Transparent,

            Overlay = RenderQueue.Overlay,
        }

        public static readonly RenderQueueRange k_RenderQueue_AllOpaque = new RenderQueueRange { lowerBound = (int)(Priority.Terrain), upperBound = (int)Priority.OpaqueLast };
        public static readonly RenderQueueRange k_RenderQueue_AllOpaqueAndHair = new RenderQueueRange { lowerBound = (int)(Priority.Terrain), upperBound = (int)Priority.Hair };

    }

}


