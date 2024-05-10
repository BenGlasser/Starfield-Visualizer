Shader "Custom/RippleShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            // Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
            #pragma exclude_renderers d3d11 gles
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;

            float _UpperFeather;
            float _LowerFeather;
            float _RippleIntensity;
            float _RippleSpeed;
            float _AudioBands[8];

            fixed4 frag (v2f i) : SV_Target
            {
                float2 newUV = ((i.uv *2.0 - 1.0)  * _ScreenParams.xy) / _ScreenParams.y;
                
                float timer = _RippleSpeed*_Time.y ;

                float len = length(newUV);

                float finalRing = smoothstep(0,1,sin(len * 5 - timer) * 0.5 + 0.5);

                float2 finalUV = i.uv - newUV * finalRing * _RippleIntensity;

                fixed4 col = tex2D(_MainTex, finalUV);

                return fixed4(col.rgb,1);
            }
            ENDCG
        }
    }
}
