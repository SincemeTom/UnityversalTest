Shader "Unlit/PreIntegraed"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //#include "UnityCG.cginc"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;

                float4 vertex : SV_POSITION;
            };

			/*Using a screen pane uv coord to draw this lut texture
			**Radius defualt value is equal to 1
			**offset defualt value is equal to 0
			*/

			static const float3 Vlist0 = float3(0.0064, 0.0484, 0.187);
			static const float3 Vlist1 = float3(0.567, 1.99, 7.41);
			static const float VList[6] = { 0.0064, 0.0484, 0.187, 0.567, 1.99, 7.41 };
			static const float3 ColorList[6] =
			{
				float3(0.233, 0.455, 0.649),
				float3(0.1, 0.366, 0.344),
				float3(0.118, 0.198, 0),
				float3(0.113, 0.007, 0.007),
				float3(0.358, 0.004, 0),
				float3(0.078, 0, 0)
			};
			float3 CreatePreIntegratedSkinBRDF(float2 uv, float offset, float Radius)
			{
				//float PI = 3.14159265359;
				//uv.x = 1 - uv.x;
				float Theta = (offset - uv.x) * PI;

				float3 A = 0;
				float3 B = 0;
				float x = -PI / 2;
				for (int i = 0; i < 1000; i++)
				{
					float step = 0.001;

					float dis = abs(2 * (1 / (1 - uv.y) * Radius) * sin(x * 0.5));
					float3 Guss0 = exp(-dis * dis / (2 * VList[0])) * ColorList[0];
					float3 Guss1 = exp(-dis * dis / (2 * VList[1])) * ColorList[1];
					float3 Guss2 = exp(-dis * dis / (2 * VList[2])) * ColorList[2];
					float3 Guss3 = exp(-dis * dis / (2 * VList[3])) * ColorList[3];
					float3 Guss4 = exp(-dis * dis / (2 * VList[4])) * ColorList[4];
					float3 Guss5 = exp(-dis * dis / (2 * VList[5])) * ColorList[5];
					float3 D = Guss0 + Guss1 + Guss2 + Guss3 + Guss4 + Guss5;

					A += saturate(cos(x + Theta)) * D;
					B += D;
					x += 0.01;

					if (x == (PI / 2))
					{
						break;
					}
				}
				float3 result = A / B;

				//return B;
				return result;
			}

			//Custom mian function
			float3 Main(in float2 uv, in float Radius, in float offset)
			{
				return CreatePreIntegratedSkinBRDF(uv, offset, Radius);
			}

            v2f vert (appdata v)
            {
                v2f o;

				float3 positionWS = TransformObjectToWorld(v.vertex.xyz).xyz;
				float4 positionCS = TransformWorldToHClip(positionWS.xyz);

                o.vertex = positionCS;
				o.uv = v.uv;
                return o;
            }

			float PreIntegratedSin()
			{
				//float PI = 3.1415927;
				float begin = 0;
				float end = PI / 2;
				float x = begin;
				float teta = 0.01;

				float sum = 0;

				for (int i = 0; i < 4096; i++)
				{
					sum += sin(x) * teta;
					x += teta;
					if (x >= end)
						break;
				}

				return sum;
			}
            float4 frag (v2f i) : SV_Target
            {
				float3 prs = CreatePreIntegratedSkinBRDF(i.uv, 0, 1);
				//prs = ColorList[0];
				/*float p = PreIntegratedSin();
				if (p < 1.004)
				{
					prs = float3(1, 0, 0);
				}
				else if (p >= 1.004 && p <= 1.005)
				{
					prs = float3(0, 1, 0);
				}
				else
				{
					prs = float3(0, 0, 1);
				}*/
				//prs = ColorList[2];
				return float4(prs, 1);
            }
            ENDHLSL
        }
    }
}
