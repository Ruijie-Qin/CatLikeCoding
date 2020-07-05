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
};

Interpolators MyVertexProgram(VertexData v)
{
    Interpolators i;
    i.uv = TRANSFORM_TEX(v.uv, _MainTex);
    i.position = UnityObjectToClipPos(v.position);
    i.normal = UnityObjectToWorldNormal(v.normal);
    i.normal = normalize(i.normal);
    i.worldPos = mul(unity_ObjectToWorld, v.position);
    return i;
    // return 0; // 等价于 return float4(0,0,0,0)
}

float4 MyFragmentProgram(Interpolators i) : SV_TARGET
{
    i.normal = normalize(i.normal);
    float3 lightDir = _WorldSpaceLightPos0.xyz;
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
    float3 lightColor = _LightColor0.rgb;
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
    UnityLight light;
    light.color = lightColor;
    light.dir = lightDir;
    light.ndotl = DotClamped(i.normal, lightDir);
    UnityIndirect indirectLight;
    indirectLight.diffuse = 0;
    indirectLight.specular = 0;
    
    return UNITY_BRDF_PBS(albedo, specularTint, oneMinusRelfectivity,
        _Smoothness, i.normal, viewDir, light, indirectLight);
}