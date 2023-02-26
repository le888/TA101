#include "UnityCG.cginc"
// #define DistanceToProjectionWindow 5.671281819617709             //1.0 / tan(0.5 * radians(20));
// #define DPTimes300 1701.384545885313                             //DistanceToProjectionWindow * 300
#define SAMPLE_COUNT 32

float _SSSScale;
float4 _Kernel[SAMPLE_COUNT], _ScreenSize, _CameraDepthTexture_TexelSize,_SkinDepthRT_TexelSize;
sampler2D _MainTex, _CameraDepthTexture,_SkinDepthRT;
float _FOV;
float _MaxDistance;
struct MeshData
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct Vertex2Fragment
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
};

Vertex2Fragment vert(MeshData v)
{
    Vertex2Fragment o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.uv;
    return o;
}

float4 SeparableSubsurface(float4 SceneColor, float2 UV, float2 SSSIntencity,float Scale)
{
    float DistanceToProjectionWindow =  1.0 / tan(0.5 * radians(_FOV));
    float D300 = DistanceToProjectionWindow*300;//300是相机的远裁剪距离，相当于求出最远距离 再屏幕上的大小
    float SceneDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_SkinDepthRT, UV));//相机空间的 线性距离(像素到相机的距离)
    float BlurLength = DistanceToProjectionWindow / SceneDepth;//模糊的长度
    float2 UVOffset = SSSIntencity * BlurLength;//模糊像素的长度
    float4 BlurSceneColor = SceneColor;
    BlurSceneColor.rgb *= _Kernel[0].rgb;

    //UNITY_LOOP写for循环的时候加上这个编译器指令
    UNITY_LOOP
    for (int i = 1; i < SAMPLE_COUNT; i++)
    {
        float2 SSSUV = UV + _Kernel[i].a * UVOffset;
        float4 SSSSceneColor = tex2D(_MainTex, SSSUV);//周围像素的颜色
        float SSSDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_SkinDepthRT, SSSUV)).r;//周围像素的深度
        float delta = abs(SceneDepth - SSSDepth);//如果原像素与目标像素差距过大，那么不进行次表面散射操作
        
        float SSSScale = saturate(D300 * Scale * delta);
        if(delta>_MaxDistance)
            SSSScale =1;
        SSSSceneColor.rgb = lerp(SSSSceneColor.rgb, SceneColor.rgb, SSSScale);//在原像素与周围像素之间进行插值，相当于周围的像素影响到了原像素 
        BlurSceneColor.rgb += _Kernel[i].rgb * SSSSceneColor.rgb;
    }
    // return  tex2D(_MainTex, UV);
    return BlurSceneColor;
}
