#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"

float4 _Tint;
sampler2D _MainTex;
float4 _MainTex_ST;
float _Smoothness;
//float4 _SpecularTint;
float _Metallic;

struct VertexData
{
    float4 position : POSITION;
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;
};

struct Interpolators
{
    float4 position : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
    float3 worldPos: TEXCOORD2;
    #if defined(VERTEXLIGHT_ON)
        float3 vertexLightColor : TEXCOORD3;
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

Interpolators MyVertexProgram(VertexData v)
{
    Interpolators i;
    i.uv = TRANSFORM_TEX(v.uv, _MainTex);
    i.position = UnityObjectToClipPos(v.position);
    i.normal = UnityObjectToWorldNormal(v.normal);
    i.worldPos = mul(unity_ObjectToWorld, v.position);
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
    UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
    light.color = _LightColor0.rgb * attenuation;
    light.ndotl = DotClamped(i.normal, light.dir);
    return light;
}

float4 MyFragmentProgram(Interpolators i) : SV_TARGET
{
    i.normal = normalize(i.normal);
    //float3 lightDir = _WorldSpaceLightPos0.xyz;
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
    //float3 lightColor = _LightColor0.rgb;
    float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;
    float3 specularTint;// = albedo * _Metallic;
    float oneMinusRelfectivity;// = 1 - _Metallic;
    albedo = DiffuseAndSpecularFromMetallic(albedo, _Metallic, specularTint, oneMinusRelfectivity);
    //albedo *= oneMinusRelfectivity;
    //albedo = EnergyConservationBetweenDiffuseAndSpecular(albedo, _SpecularTint.rgb,
    //    oneMinusRelfectivity);
    //albedo *= 1 - max(_SpecularTint.r, max(_SpecularTint.g, _SpecularTint.b));
    //float3 diffuse = albedo * lightColor * DotClamped(lightDir, i.normal);
    //float3 reflectionDir = reflect(-lightDir, i.normal);
    //float3 halfVector = normalize(lightDir +  viewDir);
    //float3 specular = specularTint * lightColor * pow(DotClamped(halfVector, i.normal), _Smoothness * 100);
    //return float4(diffuse + specular, 1);
    //UnityLight light;
    //light.color = lightColor;
    //light.dir = lightDir;
    //light.ndotl = DotClamped(i.normal, lightDir);
    //UnityIndirect indirectLight;
    //indirectLight.diffuse = 0;
    //indirectLight.specular = 0;
    
    return UNITY_BRDF_PBS(albedo, specularTint, oneMinusRelfectivity,
        _Smoothness, i.normal, viewDir, CreateLight(i), CreateIndirectLight(i));
}

#endif