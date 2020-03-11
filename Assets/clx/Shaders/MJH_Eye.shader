Shader "MJH/Eye"
{
	Properties
	{
		[Toggle (PointCloudEnable)] PointCloudEnable("PointCloudEnable",float) = 0
		_MainTex ("Base", 2D) = "white" {}
		BaseMapBias ("BaseMapBias ", Range(-1,1)) = -1
		_MixTex ("Mix", 2D) = "white" {}
		_MaskMap("Mask", 2D) = "black"{}
		_NormalTex ("Normal", 2D) = "normal" {}
		NormalMapBias ("NormalMapBias ", Range(-1,1)) = -0.5
		_EnvMap ("Reflect", 2D) = "black" {}


		AliasingFactor ("AliasingFactor", Range(0,1)) = 0.2
		EnvStrength ("EnvStrength", Range(0,10)) = 1
		ShadowColor ("ShadowColor", Vector) = (0.1122132,0.3493512,0.00003981071,0.5)

		EnvInfo ("EnvInfo", Vector) = (0,0.01,1,2.5)
		
		cEmissionScale ("cEmissionScale", Vector) = (1,1,1,1)
		[HDR]cVirtualLitColor ("cVirtualLitColor", Color) = (1, 0.72, 0.65, 0)
		cVirtualLitDir ("cVirtualLitDir", Vector) = (-0.5, 0.114 , 0.8576, 0.106)
		[HDR]_EyeColor("_EyeColor", Color) = (0.1973174,0.1973174,0.1973174,1)

		_ColorTransform0("ColorTransform0", Vector) = (0.897 ,0,	0,	0)
		_ColorTransform1("ColorTransform1", Vector) = (0.897 ,0,	0,	0)
		_ColorTransform2("ColorTransform2", Vector) = (0.897 ,0,	0,	0)

		_ColorTransform3("ColorTransform3", Vector) = (1, 0, 0, 0)
		_ColorTransform4("ColorTransform4", Vector) = (0, 1, 0, 0)
		_ColorTransform5("ColorTransform5", Vector) = (-0.001,-0.001,1,0)

	}
	SubShader
	{
		Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
		LOD 300

			// ------------------------------------------------------------------
			//  Forward pass. Shades all light in a single pass. GI + emission + Fog
		Pass
		{
			// Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
			// no LightMode tag are also rendered by Universal Render Pipeline
			Name "ForwardLit"
			Tags{"LightMode" = "UniversalForward"}

			ZWrite Off
			ZTest Equal

			HLSLPROGRAM
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
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

			#pragma vertex vert
			#pragma fragment frag
			
			#include "MJH_Common.hlsl"



			sampler2D _MixTex;
			sampler2D _NormalTex;
			sampler2D _MaskMap;



			half AliasingFactor;

			half BaseMapBias;
			half NormalMapBias;
			half4 cVirtualLitDir;
			half4 cVirtualLitColor;
			half4 cEmissionScale;
			float cVirtualColorScale;

			float4 _EyeColor;


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
				half3 userData1 = half3(0.5,0.5,0.5);
				// sample the texture
				half4 texBase = tex2Dbias (_MainTex, half4(i.uv.xy, 0, BaseMapBias));
				half4 texN = tex2Dbias (_NormalTex, half4(i.uv.xy, 0, NormalMapBias));
				texN.y = 1 - texN.y;
                half4 unpackNormal = MJH_UnpackNormal(texN);
				half4 texMask = tex2D(_MaskMap, i.uv.xy);
				half3 refMask = texMask.xyz;

				half mask = refMask.b;

				float eyeBright = lerp(0.2,5,mask);
				//Color 
                half SSSMask = 1 - unpackNormal.w;
				half3 alpha = texBase.a;
				half3 BaseColor = texBase.rgb /** texBase.rgb*/;
				BaseColor = ApplyColorTransform(BaseColor, SSSMask, mask);


				float3 SpecularColor=float3(0.04,0.04,0.04);

				//Normal
				float3 vsNormal = normalize(i.world_normal.xyz);
				half3 normalTex = half3(texN.rgb * 2.0 - 1.0);
				half3 normalVec = i.world_tangent * normalTex.x + i.world_binormal * normalTex.y + i.world_normal * normalTex.z;
				half normalLen = sqrt(dot(normalVec,normalVec));
				normalVec /= normalLen;
				float3 derNormal = normalVec - vsNormal;

				//Roughness

				half roughness = 0.3;


				//Light & View Vector
				half3 lightDir = normalize(_WorldSpaceLightPos0.www*(-i.worldPos) + _WorldSpaceLightPos0.xyz);
				half3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos.xyz));


				//GI :Messiah引擎GI数据还原

				half4 GILighting = half4(0,0,0,0);
				GILighting.xyz = DynamicGILight(normalVec);
				GILighting.w = 1;//MixMap .z ao

				half ssao = 1;
				GILighting.w = min(GILighting.w, ssao);

				//half metalic = texM.y;//MixMap .y metalic
				//half3 SpecularColor = lerp(0.04,BaseColor,metalic);
				half3 DiffuseColor = BaseColor / 3.141593;
  				//half3 DiffuseColor = (BaseColor - BaseColor * metalic) / 3.141593;


				half3 refNormal = normalize(normalVec - 2 * derNormal);
				half3 reflectDir = reflect(-viewDir,refNormal);
				half NdotV = clamp(dot(viewDir,normalVec),0,1);
				half refNdotV = saturate(dot(refNormal, viewDir));
				half NdotL = dot(normalVec,lightDir);
				half3 SunColor = half3(0,0,0);
				SunColor = _LightColor0.rgb;

				//Shadow
				half shadow = 1;

#ifdef _MAIN_LIGHT_SHADOWS
				shadow = GetMainLightShadowAttenuation(i.shadowCoord);
#endif
				//shadow = shadow * clamp (abs(NdotL) + 2.0 * texM.z * texM.z - 1.0, 0.0, 1.0);
				

				//SunColor

				float3 SunColor2 = SunColor.xyz * userData1.x * 2 * ShadowColor.g;
				SunColor2*= cPointCloudm[0].w;
				GILighting.rgb *= userData1.y * 2;

				float3 DirectLight = saturate(dot(normalize(normalVec + derNormal * 0.5), lightDir)) * shadow;
				DirectLight *= SunColor2.xyz;

				float3 DirectLight2 = saturate(dot(normalize(normalVec + derNormal * 3), lightDir)).rrr;
				DirectLight2 *= DirectLight2;

				DirectLight2 *= shadow * SunColor2 * alpha * 20 * _EyeColor.xyz;

				//virtualLight

				float3 VirtualLitDir = normalize(cVirtualLitDir);
				float3 VirtualLitColor = cVirtualLitColor.xyz * userData1.z * 2;
				float3 VirtualLitNoL = saturate(dot(normalVec, VirtualLitDir));
				float3 VirtualLight = VirtualLitNoL * VirtualLitColor;


				float3 VirtualLit2NdotL = saturate(dot(normalize(normalVec + derNormal * 5 ), VirtualLitDir)).xxx;
				float3 VirtualLight2 = VirtualLit2NdotL * VirtualLit2NdotL * VirtualLitColor * alpha * 10 * _EyeColor.xyz;


				//lighting
				float3 lighting = GILighting.xyz + DirectLight + DirectLight2 + VirtualLight + VirtualLight2;

				//return half4(lighting * 0.1,1);

				//Specular

				float3 EnvBRDF = EnvBRDFApprox(SpecularColor, roughness, NdotV);


				float H = normalize(viewDir + lightDir);
				float3 DirectSpecular = pow(max(0.0001,dot(refNormal, H)), 500) * SunColor2.rgb * shadow * eyeBright;
				float virtualreflectDir = normalize(viewDir + VirtualLitDir);

				//float3 VirtualSpecular = pow(max(0.0001,dot(reflectDir, viewDir)),500) * VirtualLight * eyeBright;
				float3 VirtualSpecular = pow(max(0.0001,dot(refNormal, viewDir)),500) * VirtualLight * eyeBright;	

				float F = 1 - NdotV;
				F *= F *F *F;

				float3 env_ref = GetIBLIrradiance(0, reflectDir) * (F + 0.1);
				
				float3 env_ref2 = GetIBLIrradiance(roughness, reflectDir) * EnvBRDF;
				float3 EnvSpec = 0.5 * (env_ref2 + env_ref) *  dot(GILighting.rgb, float3(0.3,0.59,0.11));

				float3 Specular = DirectSpecular + VirtualSpecular + EnvSpec;

				Specular += LightingPS_SPEC(i.worldPos.xyz, refNormal, viewDir, refNdotV, EnvBRDF * 2,saturate(roughness),lighting.rgb);
 				Specular *= refMask.g;//睫毛阴影


				//Final Color
				float3 FinalColor = Specular + lighting * DiffuseColor.rgb;
				//Apply Fog
				
				float3 Color = FinalColor;

				//Apply Fog
				float VdotL = saturate(dot(-viewDir, lightDir));
				Color = ApplyFogColor(Color, i.worldPos.xyz, viewDir.xyz, VdotL, EnvInfo.z);

				//Liner to Gamma
				//Color.xyz = Color.xyz / (Color.xyz * 0.9661836 + 0.180676);

				return half4 (Color.xyz, 1);
			}
			
			ENDHLSL
		}
		UsePass "MJH/Shadow/ShadowCaster"
		UsePass "MJH/Shadow/DepthOnly"
	}
}
