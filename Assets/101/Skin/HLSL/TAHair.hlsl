#ifndef HAIR__
#define HAIR__

float3 ShiftTangent(float3 tangent, float3 normal, float3 shift)
{
    float3 shiftedT = tangent + shift*normal;
    return normalize(shiftedT);
}

float3 StrandSpecular(float3 T,float3 V,float3 L,float exponent)
{
    float3 H = normalize(L+V);
    float TdotH = dot(T,H);
    float sinTH = sqrt(1-TdotH*TdotH);
    float dirAtten = smoothstep(-1,0.0,TdotH);
    return dirAtten * pow(sinTH,exponent);
}

/*
float4 HairLighting(float3 tangent,float3 normal,float3 lightVec,float3 viewVec,float2 uv,float ambOcc)
{
    //shift tangents
    float shiftTex = tex2D(shiftTex,uv) - 0.5;
    float3 t1 = ShiftTangent(tangent,normal,Shift1 + shiftTex);
    float3 t2 = ShiftTangent(tangent,normal,Shift2 + shiftTex);
    
    //diffuse lighting : the lerp shifts the shadow boundary for a softer look
    float3 diffuse = saturate(lerp(0.25,1.0,dot(normal,lightVec)));
    diffuse*= diffuseColor;
    
    //specular lighting
    float3 specular = specularColor1 * StrandSpecular(t1,viewVec,lightVec,specularExponent1);
    specular += specularColor2 * StrandSpecular(t2,viewVec,lightVec,specularExponent2);
    
    //final color assembly
    float4 color = tex2D(diffuseTex,uv);
    
    color.rgb *= (diffuse + specular)* lightColor;
    o.rgb * ambOcc;
    return color;
}
*/
#endif