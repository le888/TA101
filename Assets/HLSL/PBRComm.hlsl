#ifndef _PBRCOMM_
#define _PBRCOMM_

/////////////////////diffuse//////////////////
float OrenNayarDiffuse(
    float3 lightDirection,
    float3 viewDirection,
    float3 surfaceNormal,
    float roughness,
    float albedo)
{
    float LdotV = dot(lightDirection, viewDirection);
    float NdotL = dot(lightDirection, surfaceNormal);
    float NdotV = dot(surfaceNormal, viewDirection);

    float s = LdotV - NdotL * NdotV;
    float t = lerp(1.0, max(NdotL, NdotV), step(0.0, s));

    float sigma2 = roughness * roughness;
    float A = 1.0 + sigma2 * (albedo / (sigma2 + 0.13) + 0.5 / (sigma2 + 0.33));
    float B = 0.45 * sigma2 / (sigma2 + 0.09);

    return albedo * max(0.0, NdotL) * (A + B * s / t) / PI;
}

/////////////////DFG/////////////////////
//Cook-Torrance BRDF
#ifndef PI
#define PI 3.14159265358979323846
#endif

#ifndef HALF_MIN
#define HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_Float_Formats
#endif

#ifndef HALF_MIN_SQRT
#define HALF_MIN_SQRT 0.0078125  // 2^-7 == sqrt(HALF_MIN), useful for ensuring HALF_MIN after x^2
#endif

//D
//Trowbridge-Reitz GGX
float D_GGX(float3 N, float3 H, float Roughness)
{
    float a = max(0.001, Roughness * Roughness);
    float a2 = a * a;
    float NdotH = saturate(dot(N, H));
    float NdotH2 = NdotH * NdotH;
    float nom = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;
    return nom / max(denom, 0.001); //防止分母为0
}

float D_GGXAniso(float ax, float ay, float NoH, float3 H, float3 X, float3 Y)
{
    float XoH = dot(X, H);
    float YoH = dot(Y, H);
    float d = XoH * XoH / (ax * ax) + YoH * YoH / (ay * ay) + NoH * NoH;
    return 1 / (PI * ax * ay * d * d);
}

float D_Charlie_C(float roughness, float NoH) {
    // Estevez and Kulla 2017, "Production Friendly Microfacet Sheen BRDF"
    float invAlpha  = 1.0 / roughness;
    float cos2h = NoH * NoH;
    float sin2h = max(1.0 - cos2h, 0.0078125); // 2^(-14/2), so sin2h^2 > 0 in fp16
    return (2.0 + invAlpha) * pow(sin2h, invAlpha * 0.5) / (2.0 * PI);
}

//Schlick Fresnel
float3 F_Schlickss(float3 F0, float3 N, float3 V)
{
    float VdotH = saturate(dot(V, N));
    return F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);
}

//UE4 Black Ops II modify version
float2 EnvBRDFApprox(float Roughness, float NV)
{
    // [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
    // Adaptation to fit our G term.
    const float4 c0 = {-1, -0.0275, -0.572, 0.022};
    const float4 c1 = {1, 0.0425, 1.04, -0.04};
    float4 r = Roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * NV)) * r.x + r.y;
    float2 AB = float2(-1.04, 1.04) * a004 + r.zw;
    return AB;
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r * r) / 8.0;

    float nom = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return nom / denom;
}

float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx1 = GeometrySchlickGGX(NdotV, roughness);
    float ggx2 = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}


//////////////////////////indrect/////////////////////////
float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
{
    float r = 1.0 - roughness;
    return F0 + (max(r.xxx, F0) - F0) * pow(1.0 - cosTheta, 5.0);
}

float GeometrySchlickGGXInderect(float NdotV, float roughness)
{
    float a = roughness;
    float k = (a * a) / 2.0;

    float nom = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return nom / denom;
}

float GeometrySmithInderect(float N, float V, float L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2 = GeometrySchlickGGXInderect(NdotV, roughness);
    float ggx1 = GeometrySchlickGGXInderect(NdotL, roughness);

    return ggx1 * ggx2;
}

#endif
