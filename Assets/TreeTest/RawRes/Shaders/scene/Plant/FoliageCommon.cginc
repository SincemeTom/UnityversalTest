#ifndef FOLIAGE_MOVE_INCLUDE
#define FOLIAGE_MOVE_INCLUDE

float _WindPowers;
float _WindWeight;
float _WindSpeed;

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