#ifndef PLANT_WIND_MOVE_INCLUDE
#define PLANT_WIND_MOVE_INCLUDE

half4 _WorldOffset;

half _RotateUV;
half _WindStength, _GustWindScale, _GrassTrembleScale, _WindForceScale,_WindPower;
half _GustWindSpeed;
half _GustWindPower;
half _GrassTrembleSpeed;
half _GrassTremblePower;
half _WindForceSpeed;

float2 noiseGeneratorFunction(float2 p)
{
	p = p % 289;
	float x = ((34 * p.x + 1) * p.x) % 289 + p.y;
	x = ((34 * x + 1) * x) % 289;
	x = frac(x / 41) * 2 - 1;
	return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
}

half noiseGenerator(half2 p)
{
	half2 ip = floor(p);
	half2 fp = frac(p);
	half d00 = dot(noiseGeneratorFunction(ip), fp);
	half d01 = dot(noiseGeneratorFunction(ip + half2(0, 1)), fp - half2(0, 1));
	half d10 = dot(noiseGeneratorFunction(ip + half2(1, 0)), fp - half2(1, 0));
	half d11 = dot(noiseGeneratorFunction(ip + half2(1, 1)), fp - half2(1, 1));
	fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
	return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
}

half2 rotateRadians(half2 UV, half2 Center, half Rotation)
{
	//rotation matrix
	UV -= Center;
	half s = sin(Rotation);
	half c = cos(Rotation);

	//center rotation matrix
	half2x2 rMatrix = half2x2(c, -s, s, c);
	rMatrix *= 0.5;
	rMatrix += 0.5;
	rMatrix = rMatrix * 2 - 1;

	//multiply the UVs by the rotation matrix
	UV.xy = mul(UV.xy, rMatrix);
	UV += Center;

	return UV;
}

half Remap_value(half In, half2 InMinMax, half2 OutMinMax)
{
	half Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
	return Out;
}

half2 CalcPlantWindMoveOffset(half4x4 mat, half4 vertex, fixed weight)
{
	//half3 worldLightDir = _WorldSpaceLightPos0.xyz;
	half3 worldLightDir = fixed3(1,0,0);
	half4 glrassPos = mul(mat, vertex);
	//half4 glrassPos = mul(unity_ObjectToWorld, vertex);
	half2 RotateUV = rotateRadians(glrassPos.xz, half2(0.5, 0.5), _RotateUV);

	// wind generator
	half2 gustWind = sin(pow(noiseGenerator((RotateUV.xy *_GustWindScale + _Time.g*_GustWindSpeed) * 2) + 0.5, 1) * cos(_Time.g*_GustWindSpeed) * 2 + 0.5)*_GustWindPower;
	half2 grassTremble = (noiseGenerator((RotateUV.xy*_GrassTrembleScale + _Time.g*_GrassTrembleSpeed) * 12) * 2 + 0.5)* vertex.xyz*_GrassTremblePower;
	half2 finalWind = lerp(0, min(1, gustWind), gustWind) + (noiseGenerator((RotateUV.xy*_WindForceScale + _Time.g *_WindForceSpeed) * 1) + 0.5);
	
	half2 offset = weight * (worldLightDir*clamp(sin(_Time.g*0.3 + 0.3), 0.3, 1)) * (finalWind*_WindStength + grassTremble)*_WindPower;

	return offset;
}

#endif // PLANT_WIND_MOVE_INCLUDE