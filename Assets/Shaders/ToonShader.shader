Shader "Unlit/ToonShader"
{
    Properties
    {
        _Color("Color", Color) = (0.5, 0.65, 1, 1)
		_MainTex("Main Texture", 2D) = "white" {}
        
        [HDR]
        _AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1)
        
        [HDR]
        _SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)
        _Glossiness("Glossiness", Float) = 32
        
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimAmount("Rim Amount", Range(0, 1)) = 0.716
        _RimThreshold("Rim Threshold", Range(0, 1)) = 0.1
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
            "RenderPipeline" = "UniversalPipeline"
            "LightMode" = "UniversalForward"
        }
        LOD 200
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma fullforwardshadows
            
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                SHADOW_COORDS(2)
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldNormal : NORMAL;
                float3 viewDir : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                TRANSFER_SHADOW(o)
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                return o;
            }

            float4 _Color;
            float4 _AmbientColor;
            float _Glossiness;
            float4 _SpecularColor;
            float4 _RimColor;
            float _RimAmount;
            float _RimThreshold;
            
            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = normalize(i.worldNormal);
                float NdotL = dot(_WorldSpaceLightPos0, normal);
                float shadow = SHADOW_ATTENUATION(i);
                float lightIntensity = smoothstep(0, 0.01, NdotL * shadow);
                float4 light = lightIntensity * _LightColor0;
                
                // sample the texture
                fixed4 sample = tex2D(_MainTex, i.uv);

                float3 viewDir = normalize(i.viewDir);
                
                float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
                float NdotH = dot(normal, halfVector);

                float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);
                float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);
                float4 specular = specularIntensitySmooth * _SpecularColor;

                float4 rimDot = 1 - dot(viewDir, normal);
                float rimIntensity = rimDot * pow(NdotL, _RimThreshold);
                rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
                float4 rim = rimIntensity * _RimColor;
                
                return _Color * sample * (_AmbientColor + light + specular + rim);
            }
            ENDCG
        }
        
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
