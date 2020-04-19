#ifndef FOLIAGE_MOVE_INCLUDE
#define FOLIAGE_MOVE_INCLUDE
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Runtime/RendererFeatures/CharacterShadow/DeclareCharaterShadowMapTexture.hlsl"

#define _WorldSpaceLightPos0 _MainLightPosition
#define _LightColor0 _MainLightColor

#ifdef UNITY_COLORSPACE_GAMMA
#define unity_ColorSpaceGrey fixed4(0.5, 0.5, 0.5, 0.5)
#define unity_ColorSpaceDouble fixed4(2.0, 2.0, 2.0, 2.0)
#define unity_ColorSpaceDielectricSpec half4(0.220916301, 0.220916301, 0.220916301, 1.0 - 0.220916301)
#define unity_ColorSpaceLuminance half4(0.22, 0.707, 0.071, 0.0) // Legacy: alpha is set to 0.0 to specify gamma mode
#else // Linear values
#define unity_ColorSpaceGrey fixed4(0.214041144, 0.214041144, 0.214041144, 0.5)
#define unity_ColorSpaceDouble fixed4(4.59479380, 4.59479380, 4.59479380, 2.0)
#define unity_ColorSpaceDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)
#define unity_ColorSpaceLuminance half4(0.0396819152, 0.458021790, 0.00609653955, 1.0) // Legacy: alpha is set to 1.0 to specify linear mode
#endif

struct appdata_full {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 color :COLOR;
	float4 texcoord : TEXCOORD0;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

float _WindPowers;
float _WindWeight;
float _WindSpeed;

float3 UnityWorldSpaceViewDir(float3 worldPos)
{
	return _WorldSpaceCameraPos.xyz - worldPos;
}
inline float3 UnityWorldSpaceLightDir(in float3 worldPos)
{
	return ( - _WorldSpaceLightPos0.www * worldPos + _WorldSpaceLightPos0.xyz);

}

float4 GetShadowCoord(float4 PositionWS)
{
	return TransformWorldToShadowCoord(PositionWS.xyz);
}
half GetMainLightShadowAttenuation(float4 shadowCoord, float3 worldPos)
{
	half shadow = 1;
	Light mainLight = GetMainLight(shadowCoord);
	shadow = mainLight.shadowAttenuation;
#ifdef _CHARACTER_SHADOW			
	half cShadow = GetCharacterShadow(worldPos);
	shadow = min(shadow, cShadow);
#endif

	return shadow;
}
/** Rotates Position about the given axis by the given angle, in radians, and returns the offset to Position. */
float3 RotateAboutAxis(float4 NormalizedRotationAxisAndAngle, float3 PositionOnAxis, float3 Position)
{
	// Project Position onto the rotation axis and find the closest point on the axis to Position
	float3 ClosestPointOnAxis = PositionOnAxis + NormalizedRotationAxisAndAngle.xyz * dot(NormalizedRotationAxisAndAngle.xyz, Position - PositionOnAxis);
	// Construct orthogonal axes in the plane of the rotation
	float3 UAxis = Position - ClosestPointOnAxis;
	float3 VAxis = cross(NormalizedRotationAxisAndAngle.xyz, UAxis);
	float CosAngle;
	float SinAngle;
	sincos(NormalizedRotationAxisAndAngle.w, SinAngle, CosAngle);
	// Rotate using the orthogonal axes
	float3 R = UAxis * CosAngle + VAxis * SinAngle;
	// Reconstruct the rotated world space position
	float3 RotatedPosition = ClosestPointOnAxis + R;
	// Convert from position to a position offset
	return RotatedPosition - Position;
}

float3 SimpleGrassWind(float3 worldPos)
{

	float3 AdditionalWPO = half3(0.1, 0.1, 0.1);

	float3 direction = half3(0, 0, 1);

	float time = _Time.y;

	float3 axis = cross(direction, half3(1, 0, 0));

	float3 v0 = abs(frac(time * _WindSpeed.xxx * -0.5 + worldPos / 2) * 2 - 1);
	float angle0 = length(v0 * v0 * (3 - v0 * 2));

	float3 v1 = abs(frac(time * _WindSpeed.xxx * -0.5 * direction + worldPos / 10.24) * 2 - 1);

	float angle1 = dot(v1 * v1 * (3 - v1 * 2), direction);

	float angle = angle0 + angle1;

	float3 pivotPos = AdditionalWPO + float3(0, 0, -0.1);

	float3 RotatePositon = RotateAboutAxis(half4(axis, angle), pivotPos, AdditionalWPO);

	return (RotatePositon * _WindWeight * _WindPowers + AdditionalWPO);
}
#endif