#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

float4 _Tint;
sampler2D _MainTex, _DetailTex;
float4 _MainTex_ST, _DetailTex_ST;
sampler2D _NormalMap, _DetailNormalMap;
float _BumpScale, _DetailBumpScale;

float _Smoothness;
//float4 _SpecularTint;
float _Metallic;

struct VertexData
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent: TANGENT;
    float2 uv : TEXCOORD0;
};

struct Interpolators
{
    float4 pos : SV_POSITION;
    float4 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
    #if defined(BINORMAL_PER_FRAGMENT)
        float4 tangent: TEXCOORD2;
    #else
        float3 tangent: TEXCOORD2;
        float3 binormal: TEXCOORD3;
    #endif
    float3 worldPos: TEXCOORD4;
    
    //#if defined(SHADOWS_SCREEN)
    //    float4 shadowCoordinates : TEXCOORD5;
    //#endif
    
    SHADOW_COORDS(5)
    
    #if defined(VERTEXLIGHT_ON)
        float3 vertexLightColor : TEXCOORD6;
    #endif
};

void ComputeVertexLightColor (inout Interpolators i)
{
    #if defined(VERTEXLIGHT_ON)
        //float3 lightPos = float3(unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x);
        //float3 lightVec = lightPos - i.worldPos;
        //float3 lightDir = normalize(lightVec);
        //float ndotl = DotClamped(i.normal, lightDir);
        //float attenuation = 1 / (1 + dot(lightVec, lightVec) * unity_4LightAtten0.x);
        //i.vertexLightColor = unity_LightColor[0].rgb * ndotl * attenuation;
        i.vertexLightColor = Shade4PointLights(
            unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
            unity_LightColor[0].rgb, unity_LightColor[1].rgb,
            unity_LightColor[2].rgb, unity_LightColor[3].rgb,
            unity_4LightAtten0, i.worldPos, i.normal);
    #endif
}

float3 CreateBinormal(float3 normal, float3 tangent, float binormalSign)
{
    return cross(normal, tangent.xyz) * (binormalSign * unity_WorldTransformParams.w);
}

Interpolators MyVertexProgram(VertexData v)
{
    Interpolators i;
    i.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
    i.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);
    i.pos = UnityObjectToClipPos(v.vertex);
    i.normal = UnityObjectToWorldNormal(v.normal);
    #if defined(BINORMAL_PER_FRAGMENT)
        i.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
    #else
        i.tangent = UnityObjectToWorldDir(v.tangent.xyz);
        i.binormal = CreateBinormal(i.normal, i.tangent, v.tangent.w);
    #endif
    
    i.worldPos = mul(unity_ObjectToWorld, v.vertex);
    
    //#if defined(SHADOWS_SCREEN)
        //i.shadowCoordinates.xy = (float2(i.position.x, -i.position.y) + i.position.w) * 0.5;
        //i.shadowCoordinates.zw = i.position.zw;
        //i.shadowCoordinates = ComputeScreenPos(i.position);
    //#endif
    TRANSFER_SHADOW(i);
    
    ComputeVertexLightColor(i);
    return i;
    // return 0; // 等价于 return float4(0,0,0,0)
}

// pointLight RenderMode选择Auto，会针对每个object决定使用顶点光(Not Important)还是像素光(Important)
// 选择Auto后会根据Quality里面设置的Pixel Light Count为上限，按照某个规则排序，选了Important的排序优先级最高，
// 最后根据排序规则，超过Count的就只能是顶点光(Not Important)了
UnityIndirect CreateIndirectLight (Interpolators i)
{
    UnityIndirect indirectLight;
    indirectLight.diffuse = 0;
    indirectLight.specular =  0;
    
    #if defined(VERTEXLIGHT_ON)
        indirectLight.diffuse = i.vertexLightColor;
    #endif
    
    #if defined(FORWARD_BASE_PASS)
        indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
    #endif
    
    return indirectLight;
}
UnityLight CreateLight (Interpolators i)
{
    UnityLight light;
    //_WorldSpaceLightPos0 点光源就是pos, 平行光就是rotation
    //float3 lightVec = _WorldSpaceLightPos0.xyz - i.worldPos;
    //float attenuation = 1 / (1 + dot(lightVec, lightVec));
    #if defined(POINT) || defined(SPOT) || defined(POINT_COOKIE)
        light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
    #else
        light.dir = _WorldSpaceLightPos0.xyz;
    #endif
    
    //#if defined(SHADOWS_SCREEN)
    //    float attenuation = SHADOW_ATTENATION(i);//tex2D(_ShadowMapTexture, i.shadowCoordinates.xy / i.shadowCoordinates.w);
    //#else
    //    UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
    //#endif
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
    
    light.color = _LightColor0.rgb * attenuation;
    light.ndotl = DotClamped(i.normal, light.dir);
    return light;
}

void InitializeFragmentNormal(inout Interpolators i)
{   
    //i.normal.xy = tex2D(_NormalMap, i.uv).wy * 2 - 1;
    //i.normal.xy *= _BumpScale;
    //i.normal.z = sqrt(1 - saturate(dot(i.normal.xy, i.normal.xy)));
    float3 mainNormal = UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
    float3 detailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap, i.uv.zw), _DetailBumpScale);
    float3 tangentSpaceNormal = BlendNormals(mainNormal, detailNormal);
    #if defined(BINORMAL_PER_FRAGMENT)
        float3 binormal = CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);
    #else
        float3 binormal = i.binormal;
    #endif
    
    i.normal = normalize(tangentSpaceNormal.x * i.tangent 
        + tangentSpaceNormal.y * binormal 
        + tangentSpaceNormal.z * i.normal);
    //i.normal = float3(mainNormal.xy / mainNormal.z + detailNormal.xy / detailNormal.z, 1);
    //i.normal = BlendNormals(mainNormal, detailNormal);
    //i.normal = i.normal.xzy;
    //i.normal = normalize(i.normal);
}

float4 MyFragmentProgram(Interpolators i) : SV_TARGET
{
    InitializeFragmentNormal(i);
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
    float3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;
    albedo *= tex2D(_DetailTex, i.uv.zw) * unity_ColorSpaceDouble;
    float3 specularTint;// = albedo * _Metallic;
    float oneMinusRelfectivity;// = 1 - _Metallic;
    albedo = DiffuseAndSpecularFromMetallic(albedo, _Metallic, specularTint, oneMinusRelfectivity);
    
    
    return UNITY_BRDF_PBS(albedo, specularTint, oneMinusRelfectivity,
        _Smoothness, i.normal, viewDir, CreateLight(i), CreateIndirectLight(i));
}

#endif