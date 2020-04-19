Shader "Qin/Scene/FoliageBasicPBRPreZ" {
	Properties {
		[Toggle(_ALPHATEST_ON)]_ALPHATEST_ON("Alpha Test", float) = 0
		[Toggle(_WAVE_ON)]_WAVE_ON("Move", float) = 0
		[HideInInspector]_Color ("Ambient Color", Color) = (0,0,0,0)
		[NoScaleOffset] _BaseMap ("Base (RGB)", 2D) = "white" {}
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


		SubShader {

			Tags { "QUEUE" = "AlphaTest" "RenderType" = "Opaque" }

			LOD 100
			Pass
			{
				Name "DepthOnly"
				Tags{"LightMode" = "DepthOnly"}

				//第一次只写入深度
				ColorMask off
				ZWrite On 
				ZTest Less 
				Cull off //植被双面渲染

				HLSLPROGRAM


				#pragma prefer_hlslcc gles
				#pragma exclude_renderers d3d11_9x
				#pragma target 3.0

				#pragma vertex vert
				#pragma fragment frag

				#pragma multi_compile_instancing
				#pragma multi_compile _ _WAVE_ON
				#pragma multi_compile _ _ALPHATEST_ON	


				uniform sampler2D _MainTex; 
				uniform float4 _MainTex_ST;
				uniform half _Cutoff;
				float _CutoffMax;

				#include "FoliageCommon.hlsl"
				struct appdata {
					float4 vertex : POSITION;
					float4 color :COLOR;
					float4 texcoord : TEXCOORD0;

					UNITY_VERTEX_INPUT_INSTANCE_ID
				};
				struct v2f
				{
					float4 pos : POSITION;
					float2 uv : TEXCOORD0;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				v2f vert(appdata v)
				{
					v2f o = (v2f)0;

					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);

					o.uv = v.texcoord.xy;
					float3 positionWS = TransformObjectToWorld(v.vertex.xyz).xyz;
#ifdef _WAVE_ON
					float3 offset = SimpleGrassWind(positionWS);
					positionWS += lerp(float3(0.0, 0.0, 0.0), offset.xyz, v.color.xyz);
#endif

					float4 positionCS = TransformWorldToHClip(positionWS.xyz);

					o.pos = positionCS;


					return o;
				}

				float4 frag(v2f i) : SV_Target
				{
					UNITY_SETUP_INSTANCE_ID(i)
					half4 texcol = texcol = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
					clip(texcol.a - _Cutoff);
					return 0;
				}
				ENDHLSL
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

				HLSLPROGRAM


				// Required to compile gles 2.0 with standard srp library
				#pragma prefer_hlslcc gles
				#pragma exclude_renderers d3d11_9x
				#pragma target 3.0

				// -------------------------------------
				// Universal Pipeline keywords
				#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
				#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
				#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
				#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
				#pragma multi_compile _ _SHADOWS_SOFT
				#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

				// -------------------------------------
				// Unity defined keywords
				#pragma multi_compile _ DIRLIGHTMAP_COMBINED
				#pragma multi_compile _ LIGHTMAP_ON
				#pragma multi_compile_fog

				//--------------------------------------
				// GPU Instancing
				#pragma multi_compile_instancing

				#pragma multi_compile _ _WAVE_ON
				#pragma multi_compile _ _ALPHATEST_ON

				#include "FoliageCommon.hlsl"

				#pragma target 3.0

				#pragma vertex vert
				#pragma fragment frag



				//uniform sampler2D _BaseMap;
				uniform float4 _Color;
				uniform float4 _TintColor;

				//uniform fixed4 _SpecColor;
				uniform float _SpecLevel;
				uniform float _Shininess;
				uniform float _Contrast;
				uniform float4 _Brightness;

				uniform float _DiffLevel;
				uniform float _LightLevel;

				uniform float _Cutoff;
				float _CutoffMax;

				float _ShadowIntensity;

			
				float _SnowEffectInfluence;
				sampler2D _SnowFoliageNoise;
				float _SnowOverallThres;
				float _SnowCoverage;
				float _SnowTopIntensity;
				float EC_EmissiveWeight;

				struct VertexInput
				{
					float4 vertex       : POSITION;
					float3 normal       : NORMAL;
					float4 tangent      : TANGENT;
					half4 color         : COLOR;
					float2 texcoord     : TEXCOORD0;
					float2 lightmapUV   : TEXCOORD1;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};
				struct VertexOutput
				{
					float2 uv                       : TEXCOORD0;
					float3 vertexLight				: TEXCOORD1;

					float4 posWorld					: TEXCOORD2;    // xyz: posWS, w: Shininess * 128

					half3  normalWorld              : TEXCOORD3;
					half4 viewDir                   : TEXCOORD4;
					half3 lightDir					: TEXCOORD5;
#ifdef _MAIN_LIGHT_SHADOWS
					float4 shadowCoord              : TEXCOORD6;
#endif
					float4 vxalpha                  : TEXCOORD7;

					float4 pos						: SV_POSITION;
					UNITY_VERTEX_INPUT_INSTANCE_ID
					UNITY_VERTEX_OUTPUT_STEREO
				};


				VertexOutput vert(VertexInput v)
				{
					VertexOutput o = (VertexOutput)0;

					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

					o.uv = v.texcoord.xy;

#ifdef LIGHTMAP_OFF
					o.vertexLight = ShadeSH9(float4(o.normalWorld, 1.0)) * EC_EmissiveWeight;
#else
					o.vertexLight = float3(1, 1, 1);
#endif
					float3 positionWS = TransformObjectToWorld(v.vertex.xyz).xyz;
#ifdef _WAVE_ON
					float3 offset = SimpleGrassWind(positionWS);
					positionWS += lerp(float3(0.0, 0.0, 0.0), offset.xyz , v.color.xyz);
#endif

					float4 positionCS = TransformWorldToHClip(positionWS.xyz);

					o.posWorld = half4(positionWS, 1);
					o.pos = positionCS;

					float3 viewDirForLight = UnityWorldSpaceViewDir(o.posWorld.xyz);
					float viewLength = length(viewDirForLight);
					o.viewDir.xyz = viewDirForLight / viewLength;
					o.viewDir.w = viewLength / _CutoffMax;

					float3 normal = v.normal;
					o.normalWorld = TransformObjectToWorldNormal(normal);
			
					o.lightDir = normalize(UnityWorldSpaceLightDir(o.posWorld.xyz));

					o.vxalpha = v.color;


#if defined(_MAIN_LIGHT_SHADOWS) && !defined(_RECEIVE_SHADOWS_OFF)

#if SHADOWS_SCREEN
					o.shadowCoord = ComputeScreenPos(positionCS);
#else
					o.shadowCoord = TransformWorldToShadowCoord(o.posWorld);
#endif
#endif
					return o;
				}

				half4 frag(VertexOutput i) : SV_Target
				{

					UNITY_SETUP_INSTANCE_ID(i);
					UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				
					half4 texcol = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
					//Alpha(SampleAlbedoAlpha(i.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, half4(1,1,1,1), _Cutoff);

					float usevxalpha = i.vxalpha.a;

					half3 bump = i.normalWorld;



					half oneMinusReflectivity = unity_ColorSpaceDielectricSpec.a;
					half3 reflColor = unity_ColorSpaceDielectricSpec.rgb;

					half3 lightDir = i.lightDir.xyz;
					half3 viewDir = half3(i.viewDir.xyz);

					half NdotL = dot(bump, lightDir);
					//Specular: Blinn-Phong
					/*half3 h = normalize(lightDir + viewDir);
					half NdotL = dot(bump, lightDir);
					float nh = saturate(dot(bump, h));
					nh = lerp(0.01, 1, nh);
					float spec = pow(nh, _Shininess);*/
					float attenuation = 1;

#ifdef _MAIN_LIGHT_SHADOWS
					attenuation = GetMainLightShadowAttenuation(i.shadowCoord, i.posWorld.xyz);
#endif
					float3 attenLight = _LightColor0.rgb * attenuation;
					float3 indirectDiffuse = (UNITY_LIGHTMODEL_AMBIENT).rgb + i.vertexLight;

					float3 directDiffuse = max(0.0, NdotL) * attenLight;

					float3 diffuse = _LightLevel * texcol.rgb * (_DiffLevel * (indirectDiffuse + directDiffuse - 1) + 1);
					diffuse = clamp(diffuse, 0, 1);

					float3 colorContrasted = diffuse * _Contrast;
					float3 bright = colorContrasted + _Brightness.xxx;
					diffuse *= bright;

					/*float3 directSpecular = reflColor * _SpecColor.rgb * _SpecLevel * spec * attenLight;
					float3 specular = directSpecular;*/

					// Composite and apply occlusion
					float3 finalColor = lerp(diffuse , diffuse * _TintColor.xyz, (1-usevxalpha).xxx) /*+ specular*/;//植被不需要高光，效果很差

					//QYN_APPLY_FOG_COLOR(finalColor, i.posWorld, i)
					return half4(saturate(finalColor), 1);
				}
				ENDHLSL
			}
		
			Pass
			{
				Name "ShadowCaster"
				Tags { "LightMode" = "ShadowCaster" }

				Cull Off
				ColorMask off
				ZTest Less
				HLSLPROGRAM
				#include "FoliageCommon.hlsl"

				#pragma vertex vert
				#pragma fragment frag
				#pragma target 3.0

				#pragma multi_compile_instancing
				#pragma multi_compile _ _WAVE_ON
				#pragma multi_compile _ _ALPHATEST_ON		

				uniform sampler2D _MainTex; 
				uniform float4 _MainTex_ST;
				uniform half _Cutoff;
				float _CutoffMax;

				struct v2f
				{
					float4 pos : POSITION;
					float2 uv : TEXCOORD1;
					
				};

				v2f vert(appdata_full v)
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					o.uv = v.texcoord.xy;
					float3 positionWS = TransformObjectToWorld(v.vertex.xyz).xyz;
#ifdef _WAVE_ON
					float3 offset = SimpleGrassWind(positionWS);
					positionWS += lerp(float3(0.0, 0.0, 0.0), offset.xyz, v.color.xyz);
#endif

					float4 positionCS = TransformWorldToHClip(positionWS.xyz);
					o.pos = positionCS;
					return o;

				}

				float4 frag(v2f i) : SV_Target
				{
					half4 texcol = texcol = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
					clip(texcol.a - _Cutoff);
					return 0;
				}
				ENDHLSL
			}

			//UsePass "MJH/Shadow/ShadowCaster"
			//UsePass "MJH/Shadow/DepthOnly"
		}

	//CustomEditor "PlantsShaderGUI"
	Fallback "Transparent/Cutout/VertexLit"
}
