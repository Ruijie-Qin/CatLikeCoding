// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/My First Lighting Shader"
{
    Properties
    {
        _Tint("Tint", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "white"{}
        _Smoothness("Smoothness", Range(0, 1)) = 0.5
        [Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
        //_SpecularTint("SpecularTint", Color) = (0.5, 0.5, 0.5)
    }
	SubShader
	{
	    Pass
	    {
	        Tags {
	            "LightMode" = "ForwardBase"
	        }
            CGPROGRAM
            
            #pragma target 3.0
            #pragma vertex MyVertexProgram
            #pragma fragment MyFragmentProgram
            
            #include "My Lighting.cginc"
            
            ENDCG
	    }
	}
}
