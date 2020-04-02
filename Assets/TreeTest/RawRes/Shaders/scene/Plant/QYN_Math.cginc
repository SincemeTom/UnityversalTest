#ifndef QYN_MATH_INCLUDE
#define QYN_MATH_INCLUDE

float3 RotateAroundYInDegrees(float3 vertex, float degrees)
{
	float alpha = degrees * UNITY_PI / 180.0;
	float sina, cosa;
	sincos(alpha, sina, cosa);
	float2x2 m = float2x2(cosa, -sina, sina, cosa);
	return float3(mul(m, vertex.xy), vertex.z).xyz;
}

float pow2(float x)
{
	return x * x;
}

float pow3(float x)
{
	return (x * x) * x;
}

fixed vecMax(fixed3 aVal) {
	fixed m = max(aVal.x, aVal.y);
	m = max(m, aVal.z);
	return m;
}

fixed vecMin(fixed3 aVal) {
	fixed m = min(aVal.x, aVal.y);
	m = min(m, aVal.z);
	return m;
}

fixed vecMax(fixed4 aVal) {
	fixed m = max(aVal.x, aVal.y);
	m = max(m, aVal.z);
	m = max(m, aVal.w);
	return m;
}

float3 Hue(float H)
{
	float R = abs(H * 6 - 3) - 1;
	float G = 2 - abs(H * 6 - 2);
	float B = 2 - abs(H * 6 - 4);
	return saturate(float3(R, G, B));
}

float3 HSVtoRGB(float3 HSV)
{
	return float3(((Hue(HSV.x) - 1) * HSV.y + 1) * HSV.z);
}

float3 NormalDecode(float2 enc)
{
	float3 normal;
	normal.xy = enc.xy * 2 - 1;
	normal.z = sqrt(1 - saturate(dot(normal.xy, normal.xy)));

	return normal;
}

float3 AdjustNormal(float3 normal, float ins)
{
	return normalize(lerp(normal, float3(0, 0, 1), -ins * 3));
}

bool PostiveVec(float3 vec)
{
	if (vec.r >= 0 && vec.g >= 0 && vec.b >= 0)
	{
		return true;
	}
	return false;
}

half3 AdjustSaturation(half3 color, half sat)
{
	//fixed rgbMax = vecMax(color);
	//fixed rgbMin = vecMin(color);
	//fixed delta = rgbMax - rgbMin;
	//if (delta == 0) { return color; }
	//else
	//{
	//	fixed value = rgbMax + rgbMin;
	//	fixed L = value / 2;
	//	fixed S = delta / value;
	//	if (L >= 0.5) { S = delta / (2 - value); }

	//	if (sat >= 0)
	//	{
	//		float alpha = 0;
	//		if ((sat + S) >= 1)
	//		{
	//			alpha = S;
	//		}
	//		else
	//		{
	//			alpha = 1 - sat;
	//		}
	//		alpha = 1 / alpha - 1;
	//		return color + (color - L) * alpha;
	//	}
	//	else
	//	{
	//		return L + (color - L) * (1 + sat);
	//	}
	//}

	half n = dot(color, half3(0.2125, 0.7154, 0.0721));
	half3 intensity = half3(n, n, n);
	return lerp(intensity, color, sat + 1);
}

float3 ACESToneMapping(float3 color, float adapted_lum)
{
	static float A = 2.51f;
	static float B = 0.03f;
	static float C = 2.43f;
	static float D = 0.59f;
	static float E = 0.14f;

	color *= adapted_lum;
	return (color * (A * color + B)) / (color * (C * color + D) + E);
}

float3 QYN_UnpackNormal(float3 original)
{
	return original.xyz * 2 - 1;
}
#endif