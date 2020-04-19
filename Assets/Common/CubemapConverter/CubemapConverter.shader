Shader "Unlit/CubemapConverter"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Cubemap("Reflection Cubemap", Cube) = "_Skybox" { }
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
				float4 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
				float4 worldNormal : TEXCOORD1;
				float4 worldPos:TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			samplerCUBE _Cubemap;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldNormal = half4(worldNormal,0);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }
			/*half3 GetIBLIrradiance(in half Roughness, in float3 R)
			{
				half MIP_ROUGHNESS = 0.17;
				half level = Roughness / MIP_ROUGHNESS;
				float4 reflcol = UNITY_SAMPLE_TEXCUBE_LOD(_Cubemap, R, level);
				//return srcColor.rgb;
				return sampleEnvSpecular;

			}*/
            half4 frag (v2f i) : SV_Target
            {
                // sample the texture

				half3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

				half3 reflectDir = reflect(-viewDir, i.worldNormal);
				half fSign = reflectDir.z > 0;
				//return fSign;
				float4 reflcol = texCUBE(_Cubemap, reflectDir);


                return reflcol;
            }
            ENDCG
        }
    }
}
