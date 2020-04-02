Shader "Qin/Scene/FoliageBasicPBRPreZ" {
	Properties {

		[HideInInspector]_Color ("Ambient Color", Color) = (0,0,0,0)
		[NoScaleOffset] _MainTex ("Base (RGB)", 2D) = "white" {}
		_TintColor("Tint AO", Color) = (0.5, 0.5, 0.5, 1.0)
		_Contrast("Contrast" , Range(0, 1)) = 0.5
		_Brightness("Tint Color", Color) = (1.0, 1.0, 1.0, 1.0)

		_DiffLevel("Diffuse Level", Range(0, 2)) = 1
		_LightLevel("Lighting Level", Range(0, 2)) = 1

		_Cutoff("Cutoff Value", Range(0, 1)) = 0.5
		_CutoffMax("Cutoff Max Distance", float) = 100


		_WindPowers("Wind Powers", Range(0,2)) = 1
		_WindSpeed("Wind Speed", Range(0,2)) = 1
		_WindWeight("Wind Weight", Range(0,1)) = 1

		_SnowEffectInfluence("Snow Effect Influence", Range(0,10)) = 1
		_SnowFoliageNoise("Snow Noise", 2D) = "white" {}
		_SnowOverallThres("Snow Overall Threshold", Range(0, 1)) = 0.3
		_SnowCoverage("Snow Coverage", Range(-1,1)) = -0.2
		_SnowTopIntensity("Snow Top Intensity", Range(0,2)) = 0.8
	}

		CGINCLUDE

			#include "FoliageCommon.cginc"

		ENDCG

		SubShader {

			Name "DepthOnly"
			Tags{"LightMode" = "DepthOnly"}

			LOD 100
			Pass
			{
				Name "EarlyZ"

				//第一次只写入深度
				ColorMask off
				ZWrite On 
				ZTest Less 
				Cull off //植被双面渲染


				CGPROGRAM

				#include "UnityCG.cginc"

				#pragma vertex vert
				#pragma fragment frag
				#pragma target 3.0
				#pragma multi_compile_instancing
				#pragma fragmentoption ARB_precision_hint_fastest
				#pragma multi_compile __ _MOVE		

				uniform sampler2D _MainTex; 
				uniform float4 _MainTex_ST;
				uniform fixed _Cutoff;
				float _CutoffMax;

				struct v2f
				{
					UNITY_POSITION(pos);
					float2 uv : TEXCOORD0;

					UNITY_VERTEX_INPUT_INSTANCE_ID
					UNITY_VERTEX_OUTPUT_STEREO
				};

				v2f vert(appdata_full v)
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
					o.uv = v.texcoord.xy;
					float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

#if _MOVE
					float3 offset = SimpleGrassWind(worldPos);
					worldPos += lerp(float3(0.0, 0.0, 0.0), offset.xyz,  v.color.xyz);
#endif
					o.pos = mul(UNITY_MATRIX_VP, half4(worldPos,1));


					return o;
				}

				float4 frag(v2f i) : SV_Target
				{
					UNITY_SETUP_INSTANCE_ID(i);
					fixed4 texcol = tex2D(_MainTex, i.uv);
					clip(texcol.a - _Cutoff);
					return float4(0,0,0, 1);
				}
				ENDCG
			}
			Pass 
			{
				Name "ForwardLit"
				Tags{"LightMode" = "UniversalForward"}

				Fog { Mode Off }

				//第二次绘制像素
				Cull Off
				ZWrite Off
				ZTest Equal

				CGPROGRAM

				#pragma multi_compile_fwdbase
				#pragma multi_compile_instancing
				#pragma vertex vert
				#pragma fragment frag
				#define QYN_SHADER_PLANT_LIGHTING_MODEL 1
				#pragma multi_compile_instancing
				#pragma multi_compile_fwdbase_fullshadows
				#pragma skip_variants DIRLIGHTMAP_COMBINED VERTEXLIGHT_ON DYNAMICLIGHTMAP_ON DYNAMICLIGHTMAP_OFF LIGHTMAP_ON LIGHTMAP_OFF LIGHTMAP_SHADOW_MIXING SHADOWS_SHADOWMASK
				#pragma multi_compile __ SNOWY_WEATHER_ON

				#pragma only_renderers d3d9 d3d11 glcore gles gles3 metal d3d11_9x xboxone ps4 psp2 n3ds wiiu vulkan
				#pragma target 3.0
				#pragma multi_compile __ _MOVE	
				#pragma multi_compile __ FOG_POSTPROCESS_ON

				#include "AutoLight.cginc"
				#include "UnityCG.cginc"
				#include "Lighting.cginc"
				//#include "QYN_ShadingCommon.cginc"
				//#include "FogTransparentPP.cginc"


				uniform sampler2D _MainTex;
				uniform fixed4 _Color;
				uniform fixed4 _TintColor;

				//uniform fixed4 _SpecColor;
				uniform fixed _SpecLevel;
				uniform float _Shininess;
				uniform fixed _Contrast;
				uniform fixed4 _Brightness;

				uniform fixed _DiffLevel;
				uniform fixed _LightLevel;

				uniform fixed _Cutoff;
				float _CutoffMax;

				float _ShadowIntensity;

			
				float _SnowEffectInfluence;
				sampler2D _SnowFoliageNoise;
				float _SnowOverallThres;
				float _SnowCoverage;
				float _SnowTopIntensity;
				float EC_EmissiveWeight;

				struct appdata {
					float4 vertex : POSITION;
					float4 texcoord : TEXCOORD0;
					float3 normal : NORMAL;
					float4 color :COLOR;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct v2f {
					float4 pos : SV_POSITION;
					float2 uv : TEXCOORD0;
					fixed3 vertexLight : TEXCOORD1;
					half4 viewDir : TEXCOORD2;
					LIGHTING_COORDS(3,4)
					//half3 rimDir : TEXCOORD5;
					half3 lightDir : TEXCOORD6;
					half3 normalWorld : TEXCOORD7;
					float4 posWorld : TEXCOORD8;
					float4 vxalpha : COLOR;
					//QYN_FOG_COORDS(9, 10)
					UNITY_VERTEX_INPUT_INSTANCE_ID
				
				
				};

				v2f vert(appdata v)
				{
					v2f o=(v2f)0;

					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);

					o.uv = v.texcoord.xy;
					float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

	#if _MOVE
					float3 offset = SimpleGrassWind(worldPos);
					worldPos += lerp(float3(0.0, 0.0, 0.0), offset.xyz , v.color.xyz);

	#endif

					o.pos = mul(UNITY_MATRIX_VP, half4(worldPos, 1));
					o.posWorld = half4(worldPos,1);

					float3 viewDirForLight = UnityWorldSpaceViewDir(o.posWorld.xyz);
					float viewLength = length(viewDirForLight);
					o.viewDir.xyz = viewDirForLight / viewLength;
					o.viewDir.w = viewLength / _CutoffMax;

					o.normalWorld = UnityObjectToWorldNormal(v.normal);
				
					o.lightDir = normalize(UnityWorldSpaceLightDir(o.posWorld.xyz));

					o.vxalpha = v.color;

					o.pos = mul(UNITY_MATRIX_VP, half4(worldPos,1));

					TRANSFER_VERTEX_TO_FRAGMENT(o);

				#ifdef LIGHTMAP_OFF
					o.vertexLight = ShadeSH9(float4(o.normalWorld, 1.0)) * EC_EmissiveWeight;
				#else
					o.vertexLight = fixed3(1, 1, 1);
				#endif
					//QYN_TRANSFER_FOG(o, o.posWorld)
					return o;
				}

				fixed4 frag(v2f i) : COLOR
				{
					UNITY_SETUP_INSTANCE_ID(i);
							
					fixed4 texcol = tex2D(_MainTex, i.uv);

					float usevxalpha = i.vxalpha.a;

					half3 bump = i.normalWorld;

/*#if defined(SNOWY_WEATHER_ON)
					float foliageNoise = tex2D(_SnowFoliageNoise, i.uv);
					float upW = dot(i.normalWorld, half3(0, 1, 0));
					upW = (upW - _SnowCoverage) / (1 - _SnowCoverage);

					float snowMask = saturate((foliageNoise + _SnowTopIntensity * saturate(upW)) * _SnowEffectInfluence * SnowLevel);
					snowMask = snowMask > _SnowOverallThres ? pow(((snowMask - _SnowOverallThres) / (1 - _SnowOverallThres)), 2.0) : 0;

					texcol.rgb = lerp(texcol.rgb, 1, snowMask);
#endif*/

					fixed oneMinusReflectivity = unity_ColorSpaceDielectricSpec.a;
					fixed3 reflColor = unity_ColorSpaceDielectricSpec.rgb;

					half3 lightDir = i.lightDir.xyz;
					half3 viewDir = half3(i.viewDir.xyz);

					half NdotL = dot(bump, lightDir);
					//Specular: Blinn-Phong
					/*half3 h = normalize(lightDir + viewDir);
					half NdotL = dot(bump, lightDir);
					float nh = saturate(dot(bump, h));
					nh = lerp(0.01, 1, nh);
					float spec = pow(nh, _Shininess);*/

					UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWorld.xyz);
					float3 attenLight = _LightColor0.rgb * attenuation;
					float3 indirectDiffuse = (UNITY_LIGHTMODEL_AMBIENT).rgb + i.vertexLight;

					float3 directDiffuse = max(0.0, NdotL) * attenLight;

					float3 diffuse = _LightLevel * texcol.rgb * (_DiffLevel * (indirectDiffuse + directDiffuse - 1) + 1);
					diffuse = clamp(diffuse, 0, 1);

					float3 colorContrasted = diffuse * _Contrast;
					float3 bright = colorContrasted + _Brightness;
					diffuse *= bright;

					/*float3 directSpecular = reflColor * _SpecColor.rgb * _SpecLevel * spec * attenLight;
					float3 specular = directSpecular;*/

					// Composite and apply occlusion
					fixed3 finalColor = lerp(diffuse , diffuse * _TintColor, 1-usevxalpha) /*+ specular*/;//植被不需要高光，效果很差

					//QYN_APPLY_FOG_COLOR(finalColor, i.posWorld, i)
					return fixed4(saturate(finalColor), 1);
				}
				ENDCG
			}
		
			Pass
			{
				Name "ShadowCaster"
				Tags { "LightMode" = "ShadowCaster" }

				Cull Off

				CGPROGRAM

				#include "UnityCG.cginc"

				#pragma vertex vert
				#pragma fragment frag
				#pragma target 3.0
				#pragma multi_compile_instancing
				#pragma multi_compile_shadowcaster
				#pragma fragmentoption ARB_precision_hint_fastest
				#pragma multi_compile __ _MOVE		

				uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
				uniform fixed _Cutoff;
				float _CutoffMax;

				struct v2f
				{
					V2F_SHADOW_CASTER;
					float2 uv : TEXCOORD1;
					half4 viewDir : TEXCOORD2;
					UNITY_VERTEX_INPUT_INSTANCE_ID
					UNITY_VERTEX_OUTPUT_STEREO
				};

				v2f vert(appdata_full v)
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
					o.uv = v.texcoord.xy;
					float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

	#if _MOVE
					float3 offset = SimpleGrassWind(worldPos);
					worldPos += lerp(float3(0.0, 0.0, 0.0), offset.xyz, v.color.xyz);
	#endif

					o.pos = mul(UNITY_MATRIX_VP, half4(worldPos, 1));
					return o;

				}

				float4 frag(v2f i) : SV_Target
				{
					UNITY_SETUP_INSTANCE_ID(i);
					fixed4 texcol = tex2D(_MainTex, i.uv);
					clip(texcol.a - _Cutoff);
					SHADOW_CASTER_FRAGMENT(i)
				}
				ENDCG
			}
		}
	//CustomEditor "PlantsShaderGUI"
	Fallback "Transparent/Cutout/VertexLit"
}
