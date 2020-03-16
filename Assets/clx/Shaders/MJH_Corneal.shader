Shader "MJH/Corneal"
{
	Properties
	{
		[Toggle (PointCloudEnable)] PointCloudEnable("PointCloudEnable",float) = 0
		_MainTex ("Base", 2D) = "white" {}
		_BaseColor("Base Color", Color) = (1, 1, 1, 1)
		BaseMapBias ("BaseMapBias ", Range(-1,1)) = -1

		_MaskMap("Mix AO", 2D) = "black"{}
		_AOIntensity("AO Strength", Range(0,2)) = 0.5 
		_NormalTex ("Normal", 2D) = "normal" {}
		NormalMapBias ("NormalMapBias ", Range(-1,1)) = -0.5
		_EnvMap ("Reflect", 2D) = "black" {}
		_Roughness("_Roughness", Range(0, 1)) = 0.5
		AliasingFactor ("AliasingFactor", Range(0,1)) = 0.2
		EnvStrength ("EnvStrength", Range(0,10)) = 1
		ShadowColor ("ShadowColor", Vector) = (0.1122132,0.3493512,0.00003981071,0.5)

		EnvInfo ("EnvInfo", Vector) = (0,0.01,1,2.5)
		
		[HDR]cVirtualLitColor ("cVirtualLitColor", Color) = (1, 0.72, 0.65, 0)
		cVirtualLitDir ("cVirtualLitDir", Vector) = (-0.5, 0.114 , 0.8576, 0.106)

	}
	SubShader
	{
		Tags{"RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
		LOD 300

			// ------------------------------------------------------------------
			//  Forward pass. Shades all light in a single pass. GI + emission + Fog
		Pass
		{
			// Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
			// no LightMode tag are also rendered by Universal Render Pipeline
			Name "ForwardLit"
			Tags{"LightMode" = "UniversalForward" }
			ZWrite On
			ZTest LEqual

			Blend One Zero

			HLSLPROGRAM
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

			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing

			//--------------------------------------
			//Character Shadow
			#pragma multi_compile _ _CHARACTER_SHADOW

			//--------------------------------------
			// OPAQUE_TEXTURE
			#pragma multi_compile _ REQUIRE_OPAQUE_TEXTURE
			
			#pragma vertex vert
			#pragma fragment frag

			#include "MJH_Common.hlsl"
			//#if defined(REQUIRE_OPAQUE_TEXTURE)
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
			//#endif

			sampler2D _NormalTex;
			sampler2D _MaskMap;

			//sampler2D _BackgroundTexture;

			half AliasingFactor;
			half _Roughness;
			half BaseMapBias;
			half NormalMapBias;
			half4 cVirtualLitDir;
			half4 cVirtualLitColor;

			float cVirtualColorScale;
			float _AOIntensity;



			half4 frag (v2f i) : SV_Target
			{
				
				
				float4 cPointCloudm[6] = 
				{
					float4 (0.4153285,	0.3727325,	0.3066995,	1),
					float4 (0.6216756,	0.6451226,	0.6716674,	1),
					float4 (0.5540166,	0.7015119,	0.8980855,	1),
					float4 (0.3778813,	0.2398499,	0.05358088,	1),
					float4 (0.3423186,	0.4456023,	0.4700097,	1),
					float4 (0.6410592,	0.5083932,	0.4235953,	1)
				};
				//User Data
				 // X : Sunlight Y：GI Z：VirtualLight				
				half3 userData1 = half3(0.5,0.5,0.5);
				// sample the texture
				half4 texBase = tex2Dbias (_MainTex, half4(i.uv.xy, 0, BaseMapBias));
				
				//half4 sceneColor = tex2Dproj(_BackgroundTexture, i.screen_uv);

				half3 sceneColor = SampleSceneColor(i.screen_uv.xy);
				
				//Sample Mix texture
				half4 texMask = tex2D(_MaskMap, i.uv.xy);
				float refAlpha = (texMask.a);
				float AO = (texMask.g);
				float refmask = texMask.g;

				//Parameters
				float roughness = _Roughness;

				//Color 
				half3 BaseColor =/* texBase.rgb **/ texBase.rgb * texBase.a;
				half3 DiffuseColor = BaseColor / 3.141593;
				float3 SpecularColor=float3(0.04,0.04,0.04);

				//Normal
				/*float3 vsNormal = normalize(i.world_normal.xyz);
				half3 normalTex = half3(texN.rgb * 2.0 - 1.0);
				half3 normalVec = i.world_tangent * normalTex.x + i.world_binormal * normalTex.y + i.world_normal * normalTex.z;
				half normalLen = sqrt(dot(normalVec,normalVec));
				normalVec /= normalLen;
				float3 derNormal = normalVec - vsNormal;*/

				half3 normalVec = normalize(i.world_normal.xyz);

				//Light & View Vector & shadow
				half3 lightDir = normalize(_WorldSpaceLightPos0.www*(-i.worldPos) + _WorldSpaceLightPos0.xyz);
				half3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos.xyz));
				half3 SunColor = half3(0,0,0);
				SunColor = _LightColor0.rgb;

				half3 reflectDir = reflect(-viewDir,normalVec);
				half NdotV = clamp(dot(viewDir,normalVec),0,1);

				half NdotL = dot(normalVec,lightDir);

				//shadow
				half shadow = 1;

#ifdef _MAIN_LIGHT_SHADOWS
				shadow = GetMainLightShadowAttenuation(i.shadowCoord, i.worldPos.xyz);
#endif


				//GI :Messiah引擎GI数据还原
				half4 GILighting = half4(0,0,0,0);
				GILighting.xyz = DynamicGILight(normalVec);
				GILighting.xyz *= userData1.y * 2;
				GILighting.w = 1;//MixMap .z ao

				half ssao = 1;
				GILighting.w = min(GILighting.w, ssao);




				//SunColor

				float3 SunColor2 = SunColor.xyz * userData1.x * 2 * ShadowColor.g;
				SunColor2*= cPointCloudm[0].w;
				
				//virtualLight

				float3 VirtualLitDir = normalize(cVirtualLitDir);
				float3 VirtualLitColor = cVirtualLitColor.xyz * userData1.z * 2;
				float VirtualLitNoL = saturate(dot(normalVec, VirtualLitDir));
				float3 VirtualLight = VirtualLitNoL * VirtualLitColor;


				//lighting
				float3 lighting = GILighting.xyz + NdotL * SunColor2 * shadow + VirtualLight;

				//Specular
				float3 EnvBRDF = EnvBRDFApprox(SpecularColor, roughness, NdotV);
				float H = normalize(viewDir + lightDir);
				float3 DirectSpecular = GetDirectSPEC(roughness, lightDir, viewDir, normalVec, EnvBRDF)  * SunColor2 * NdotL * shadow;
				float3 VirtualSpecular = GetDirectSPEC(roughness, VirtualLitDir, viewDir, normalVec, EnvBRDF) * VirtualLitNoL * VirtualLitColor;
				float3 env_ref = GetIBLIrradiance(roughness, reflectDir) * AO * refAlpha;

				float3 EnvSpecular = env_ref * dot(GILighting.xyz,float3(0.3,0.59,0.11)); 
				float3 Specular =  EnvSpecular + DirectSpecular + VirtualSpecular;

				Specular += LightingPS_SPEC(i.worldPos.xyz, normalVec, viewDir, NdotV, EnvBRDF * 2,saturate(roughness),lighting.rgb);
				float3 FinalColor = Specular + lighting * DiffuseColor.rgb;

				
				//Blend
				sceneColor.xyz *=  (1 - texBase.a);
				
				sceneColor.xyz += FinalColor;
				sceneColor.xyz *=  1 - pow((1 - AO), _AOIntensity);

				float3 Color = sceneColor.xyz;
				//Final Color

				//Apply Fog
				float VdotL = saturate(dot(-viewDir, lightDir));
				Color = ApplyFogColor(Color, i.worldPos.xyz, viewDir.xyz, VdotL, EnvInfo.z);

				//Liner to Gamma

				//Color.xyz = Color.xyz / (Color.xyz * 0.9661836 + 0.180676);

				return half4 (Color.xyz, 1);
			}
			
			ENDHLSL
		}
		//UsePass "MJH/Shadow/ShadowCaster"
	}
	FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
