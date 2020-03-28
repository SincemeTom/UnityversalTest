#ifndef UNITY_DECLARE_CHARACTER_SHADOWMAP_TEXTURE_INCLUDED
#define UNITY_DECLARE_CHARACTER_SHADOWMAP_TEXTURE_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

TEXTURE2D_SHADOW(_CharacterShadowMap);
SAMPLER_CMP(sampler_CharacterShadowMap);

CBUFFER_START(_CharacterShadowBuffer)
float4x4 _CharacterShadowMatrix;
float4 _CharacterShadowmapSize;// (xy: 1/width and 1/height, zw: width and height)
float2 _CharacterShadowFilterWidth;
CBUFFER_END


ShadowSamplingData GetCharacterShadowSamplingData()
{
	ShadowSamplingData shadowSamplingData;
	shadowSamplingData.shadowOffset0 = _MainLightShadowOffset0;
	shadowSamplingData.shadowOffset1 = _MainLightShadowOffset1;
	shadowSamplingData.shadowOffset2 = _MainLightShadowOffset2;
	shadowSamplingData.shadowOffset3 = _MainLightShadowOffset3;
	shadowSamplingData.shadowmapSize = _CharacterShadowmapSize;
	return shadowSamplingData;
}

// ShadowParams
// x: ShadowStrength
// y: 1.0 if shadow is soft, 0.0 otherwise
half4 GetCharacterShadowParams()
{
	return _MainLightShadowParams;
}

float GetCharacterShadow(float3 worldPos)
{
	float shadow;
	float4 shadowCoord = mul(_CharacterShadowMatrix, half4(worldPos, 1));
	shadowCoord.xyz /= shadowCoord.w;

	ShadowSamplingData shadowSamplingData = GetCharacterShadowSamplingData();
	half4 shadowParams = GetCharacterShadowParams();
	shadow = 1 - SampleShadowmap(TEXTURE2D_ARGS(_CharacterShadowMap, sampler_CharacterShadowMap), shadowCoord, shadowSamplingData, shadowParams, false);
	shadow *= saturate(sign((shadowCoord.x - 0) * (1 - shadowCoord.x))) * saturate(sign((shadowCoord.y - 0) * (1 - shadowCoord.y)));
	return 1 - shadow;
}
#endif
