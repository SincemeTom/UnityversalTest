Shader "Qin/Scene/TrunkBasicOpt" {
	Properties {
		_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_SpecLevel ("Specular Level", float) = 1
		_Shininess ("Shininess", float) = 10
		//_RimColor ("Scattering Color", Color) = (1.0,1.0,1.0,1.0)
		//_RimLevel ("Scattering Power", Float) = 2.0
		//_RimDir ("Scattering Light Direction", Vector) = (0.0, 1.0, 0.0, 1.0)
		[HideInInspector]_Color ("Ambient Color", Color) = (0,0,0,0)
		[HideInInspector]_ShadowIntensity("Shadow Intensity", Range(0, 5)) = 1
		[NoScaleOffset] _MainTex ("Base (RGB)", 2D) = "white" {}
		[NoScaleOffset] _BumpMap ("Normal Map", 2D) = "bump" {}
		[NoScaleOffset] _BumpScale ("Normal Map Intensity", float) = 1.0
		//[NoScaleOffset] _MetallicGlossMap("Metallic Map: R(Roughness), G(Metallic), B(AO)", 2D) = "white" {}
		_DiffLevel ("Diffuse Level", Range (0, 2)) = 1
		_LightLevel ("Lighting Level", Range (0, 2)) = 1
		//_ReflLevel ("Reflection Level", Range (0, 4)) = 1
		//_Roughness ("Reflection Roughness", Range (0, 2)) = 1

		_CutoffMax ("Cutoff Max Distance", float) = 100
		_SnowEffectInfluence("Snow Effect Influence", Range(0,10))=1
	}

	SubShader {
		Tags { "QUEUE" = "Geometry" "RenderType" = "Opaque" }
		LOD 100

		Pass {
			Name "ForwardLit"
			Tags{"LightMode" = "UniversalForward"}
			Cull Back
			ZWrite Off
			ZTest Equal
			Fog { Mode Off }

			CGPROGRAM

			//#define SCREEN_SHADOW 1
			#pragma multi_compile_fwdbase
			#pragma multi_compile_instancing
			#pragma multi_compile_fwdbase_fullshadows
			//#pragma multi_compile __ RAINY_WEATHER_ON
			#pragma multi_compile __ SNOWY_WEATHER_ON
			#pragma multi_compile __ FOG_POSTPROCESS_ON
			#pragma multi_compile __ USE_NORMALMAP

			#pragma vertex vert
			#pragma fragment frag

			#pragma skip_variants DIRLIGHTMAP_COMBINED VERTEXLIGHT_ON DYNAMICLIGHTMAP_ON DYNAMICLIGHTMAP_OFF LIGHTMAP_ON LIGHTMAP_OFF
			//

			#pragma only_renderers d3d9 d3d11 glcore gles gles3 metal d3d11_9x xboxone ps4 psp2 n3ds wiiu vulkan
			#pragma target 3.0

			#include "AutoLight.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			//#include "QYN_ShadingCommon.cginc"
			#include "QYN_Math.cginc"
			//#include "FogTransparentPP.cginc"
			uniform sampler2D _MainTex;
#ifdef USE_NORMALMAP
			uniform sampler2D _BumpMap;
			uniform half _BumpScale;
#endif
			//uniform sampler2D _MetallicGlossMap;
			//uniform fixed4 _LightColor0;
			uniform fixed4 _Color;

			//uniform fixed4 _SpecColor;
			uniform fixed _SpecLevel;
			uniform float _Shininess;

			uniform fixed _DiffLevel;
			uniform fixed _LightLevel;

			//uniform fixed4 _RimColor;
			//uniform half _RimLevel;
			//uniform float4 _RimDir;

			//uniform fixed _ReflLevel;
			//uniform half _Roughness;

			float _CutoffMax;

			float _ShadowIntensity;

			float EC_EmissiveWeight;
			//float EC_EmissiveWeight;

			float _SnowEffectInfluence;

			struct appdata {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
				float3 normal : NORMAL;
#ifdef USE_NORMALMAP
				float4 tangent : TANGENT;
#endif
				float4 vxalpha :COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed3 vertexLight : TEXCOORD1;
				half4 viewDir : TEXCOORD2;
				UNITY_SHADOW_COORDS(3)
#ifdef USE_NORMALMAP
				half4 tangentWorld : TEXCOORD4;
				half4 normalWorld : TEXCOORD5;
				half4 binormalWorld : TEXCOORD6;
#else
				float3 normalWorld : TEXCOORD4;
#endif
				float4 vxalpha : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				float4 posWorld : TEXCOORD9;
				//QYN_FOG_COORDS(10, 11)
			};

			v2f vert(appdata v)
			{
				v2f o=(v2f)0;

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);	
				
				o.pos = mul(unity_ObjectToWorld, v.vertex);

				o.posWorld = o.pos;
				o.uv = v.texcoord.xy;
				o.vxalpha = v.vxalpha;
				float3 viewDirForLight = UnityWorldSpaceViewDir(o.posWorld.xyz);
				float viewLength = length(viewDirForLight);
				o.viewDir.xyz = viewDirForLight / viewLength;
				o.viewDir.w = viewLength / _CutoffMax;
				float3 lightDir = normalize(UnityWorldSpaceLightDir(o.posWorld.xyz));
				// o.lightDir = lightDir;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);

				half4x4 modelMatrix = unity_ObjectToWorld;
#ifdef USE_NORMALMAP
				o.normalWorld.xyz = normalize(mul(modelMatrix, half4(v.normal, 0.0)).xyz);
				o.tangentWorld.xyz = normalize(mul(modelMatrix, half4(v.tangent.xyz, 0.0)).xyz);
				o.binormalWorld.xyz = cross(o.normalWorld, o.tangentWorld) * v.tangent.w * unity_WorldTransformParams.w;
				o.normalWorld.w = lightDir.y;
				o.tangentWorld.w = lightDir.x;
				o.binormalWorld.w = lightDir.z;
#else
				o.normalWorld = worldNormal;
#endif

				o.vxalpha = v.vxalpha;	
				o.pos = mul(UNITY_MATRIX_VP, o.posWorld);

				float3 shlight = ShadeSH9(float4(worldNormal, 1.0)) * EC_EmissiveWeight;
				o.vertexLight = shlight;

				//QYN_TRANSFER_FOG(o, o.posWorld)

				return o;
			}

			fixed4 frag(v2f i) : COLOR
			{
				UNITY_SETUP_INSTANCE_ID(i);

				float usevxalpha = i.vxalpha.a;
				fixed4 texcol = tex2D(_MainTex, i.uv);
#ifdef USE_NORMALMAP
				half3 bump = NormalDecode(tex2D(_BumpMap, i.uv));
				bump.xy *= _BumpScale;

				half3x3 local2WorldTranspose = half3x3(i.tangentWorld.xyz, i.binormalWorld.xyz, i.normalWorld.xyz);
				bump = normalize(mul(bump, local2WorldTranspose));
#else
				half3 bump = i.normalWorld;
				half3x3 local2WorldTranspose = half3x3(float3(0,0,0), float3(0, 0, 0), i.normalWorld.xyz);
#endif
				fixed3 metallicGloss = fixed3(1, 0, 1);
/*#if defined(SNOWY_WEATHER_ON)	
				float SnowMask = SnowModifier(i.normalWorld.xyz, i.posWorld, local2WorldTranspose, 1, _SnowEffectInfluence, bump, texcol.rgb, metallicGloss.r);
#endif*/

				fixed metallic = metallicGloss.g;
				metallic *= metallic;
				fixed roughness = metallicGloss.r;
				fixed ao = metallicGloss.b;
				fixed gloss = 1.0 - roughness;
				fixed oneMinusReflectivity = unity_ColorSpaceDielectricSpec.a * (1.0 - metallic);

				fixed3 reflColor = lerp(unity_ColorSpaceDielectricSpec.rgb, texcol.rgb, metallic);

				fixed grazingTerm = max(0.05, saturate((1.0 - oneMinusReflectivity)));

				fixed3 finalColor = fixed3(0, 0, 0);

#ifdef USE_NORMALMAP
				// fixed3 lightDir = i.lightDir;
				half3 lightDir = half3(i.tangentWorld.w, i.normalWorld.w, i.binormalWorld.w);
#else
				half3 lightDir = normalize(UnityWorldSpaceLightDir(i.posWorld.xyz));
#endif
				half3 viewDir = normalize(half3(i.viewDir.xyz));

				half3 h = normalize(lightDir + viewDir);
				half NdotL = dot(bump, lightDir);
				float nh = saturate(dot(bump, h));
				float spec = pow(nh, _Shininess * max(0.2, gloss));

				//UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWorld.xyz);
				float attenuation = 1;

/*#ifdef _MAIN_LIGHT_SHADOWS
				attenuation = GetMainLightShadowAttenuation(i.shadowCoord, i.posWorld.xyz);
#endif*/
				float3 attenLight = _LightColor0.rgb * attenuation;
				float3 indirectDiffuse = (UNITY_LIGHTMODEL_AMBIENT).rgb + i.vertexLight;
				float3 directDiffuse = max(0.0, NdotL) * attenLight;
				float3 diffuse = _LightLevel * texcol.rgb * (_DiffLevel * (indirectDiffuse + directDiffuse - 1) + 1);
				diffuse = clamp(diffuse, 0, 1);

				float3 directSpecular = reflColor * _SpecColor.rgb * _SpecLevel * roughness * spec * attenLight;

				float3 specular = directSpecular;

				// Composite and apply occlusion
				finalColor += diffuse  + specular;

				float aoPower = lerp(0.2, 1, usevxalpha);
				float3 testcolor = float3(usevxalpha, usevxalpha, usevxalpha);
				finalColor *= aoPower;

				//QYN_APPLY_FOG_COLOR(finalColor, i.posWorld, i)
				return fixed4(saturate(finalColor), 1);
			}
			ENDCG
		}
		//UsePass "MJH/Shadow/ShadowCaster"
		UsePass "MJH/Shadow/DepthOnly"
	}
	//CustomEditor "PlantsTrunksShaderGUI"
	//Fallback "Diffuse"
}
