// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/My First Lighting Shader"
{
    Properties
    {
        _Tint("Tint", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "white"{}
        [NoScaleOffset] _NormalMap("Heights", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Float) = 1
        _Smoothness("Smoothness", Range(0, 1)) = 0.5
        [Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
        _DetailTex ("Detail Texture", 2D) = "gray" {}
        [NoScaleOffset] _DetailNormalMap ("Detail Normals", 2D) = "bump" {}
        _DetailBumpScale ("Detail Bump Scale", Float) =  1
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
            #pragma multi_compile _ VERTEXLIGHT_ON
            #pragma vertex MyVertexProgram
            #pragma fragment MyFragmentProgram
            
            #define FORWARD_BASE_PASS
            
            #include "My Lighting.cginc"
            
            ENDCG
	    }
	    
	    Pass
	    {
	        Tags {
	            "LightMode" = "ForwardAdd"
	        }
	        
	        Blend One One
	        ZWrite Off
	        
	        CGPROGRAM
	        #pragma target 3.0
	        #pragma vertex MyVertexProgram
	        #pragma fragment MyFragmentProgram
	        //#pragma multi_compile DIRECTIONAL POINT SPOT
	        #pragma multi_compile_fwdadd
	        //#define POINT
	        
	        #include "My Lighting.cginc"
	        ENDCG
	    }
	}
}
