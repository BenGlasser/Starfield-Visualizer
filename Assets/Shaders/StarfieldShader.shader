Shader "Custom/StarfieldShader"
{
    Properties
    {
        [NoScaleOffset]
        [NoTile]

        _MainTex ("Texture", 2D) = "white" {}
        _Num_Layers ("Number of Layers", Range(1, 100)) = 1
        _Layer_Zoom ("Layer Zoom", Range(0, 10)) = 1
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

            float2 rot(float2 uv, float a)
            {
                float c = cos(a), s = sin(a);
                float2x2 rotation_matrix = float2x2(c, -s, s, c);
                return mul(rotation_matrix, uv);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                v.uv = ((v.uv - .5)  * _ScreenParams.xy) / _ScreenParams.y; // normalize the uv
                v.uv *= 5.0; // zoom scalar
                o.uv = rot(v.uv, _Time);
                
                return o;
            }

            sampler2D _MainTex;

            int _Num_Layers;
            float _Layer_Zoom; 
            float _Bands[8]; // AudioEngine.audioBandBuffer pupulated in update from AudioEngineBus.cs

            float hash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 23.45);
                return frac(p.x * p.y);
            }

            float makeStar(float2 uv, float flair, float intensity, float ray_size)
            {
                float PI = 3.14159265359;

                float d = length(uv);      // distance from center
                float m = intensity / d;   // magnitude of the star

                float rays = max(0, 1 - abs(uv.x * uv.y * ray_size)); 
                m += rays * flair;
                
                uv =  rot(uv, PI/4); 
                rays = max(0, 1 - abs(uv.x * uv.y * ray_size));
                m += rays * .3 * flair;

                m *= smoothstep(1/* value from 0-1 determines how much of the grid cell each start takes up*/, .2, d);
                return m;
            }

            float3 starLayer(float2 uv)
            {
                float3 col = float3(0, 0, 0); // color of the star

                float2 gv = frac(uv) - 0.5; // grid value
                float2 id = floor(uv); // integer value of the uv

                for (int y = -1; y <= 1; y++)
                {
                    for (int x = -1; x <= 1; x++)
                    {
                        float2 offset = float2(x, y);
                        float2 uv = gv - offset;
                        
                        float randOffset = hash21(id + offset); // random offset
                        float size = frac(randOffset * 345.32);
                        float star = makeStar(uv - float2(randOffset, frac(randOffset*34)) + .5, smoothstep(.8, .9, size), .05, 1000); // generate the star
                        
                        float3 color = sin(float3(.2, .3, .9) * frac(randOffset*2345.2)*132.2) * .5 + .5;
                        color *= float3(1, .5, 1 + size);
                        col += star * size * color;
                    }
                }
                return col;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 col = float3(0, 0, 0);
                float time = _Time * 1; // TODO add time_scalar property
                
                // i.uv *= mul(rot(time), i.uv); // rotate the uv
                for (float g = 0; g < 1; g+= 1.0 / _Num_Layers)
                {
                    float depth = frac(g + time);
                    float scale = lerp(_Layer_Zoom, .5, depth);
                    float fade = depth * smoothstep(1, .9, depth);
                    col += starLayer(i.uv * scale + g*453.2) * fade;
                }


                return fixed4(col, 1);
            }
            ENDCG
        }
    }
}
