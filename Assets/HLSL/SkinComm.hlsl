#ifndef _TASKIN_
#define _TASKIN_

//////////////////////////////////////////////////benckman///////////////////////////////////////////
float PHBeckmann(float ndoth, float m)
{
    float alpha = acos(ndoth);
    float ta = tan(alpha);
    float val = 1.0 / (m * m * pow(ndoth, 4.0)) * exp(-(ta * ta) / (m * m));
    return val;
} // Render a screen-aligned quad to precompute a 512x512 texture.
float KSTextureCompute(float2 tex : TEXCOORD0)
{
    // Scale the value to fit within [0,1] – invert upon lookup.
    return 0.5 * pow(PHBeckmann(tex.x, tex.y), 0.1);
}


float KS_Skin_Specular(
    float3 N, // Bumped surface normal
    float3 L, // Points to light
    float3 V, // Points to eye
    float m, // Roughness
    float rho_s, // Specular brightness
    float F
    //sampler2D beckmannTex
)
{
    float result = 0.0;
    float ndotl = dot(N, L);
    if (ndotl > 0.0)
    {
        float3 h = L + V; // Unnormalized half-way vector
        float3 H = normalize(h);

        float ndoth = saturate(dot(N, H));
        // float PH = pow(2.0 * tex2D(beckmannTex, float2(ndoth, m)), 10.0);
        float PH = pow(2.0 * KSTextureCompute(float2(ndoth, m)), 10.0);
        // float F = fresnelReflectance(N, V, 0.028);
        float frSpec = max(PH * F / dot(h, h), 0);
        result = ndotl * rho_s * frSpec; // BRDF * dot(N,L) * rho_s
    }
    return result;
}

//////////////////////////////////////////////////benckman end///////////////////////////////////////////
#endif
