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

            sampler2D _MainTex;
            int _Num_Layers;
            float _Layer_Zoom; 
            float _Bands[8]; // AudioEngine.audioBandBuffer pupulated in update from AudioEngineBus.cs


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
                v.uv *= 3.0; // zoom scalar
                o.uv = rot(v.uv, _Time*1); // rotate the uv
                
                return o;
            }

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



                uv =  rot(uv, _Time * -4); 
                float rays = max(0, 1 - abs(uv.x * uv.y * ray_size)); 
                m += rays * flair;
                
                uv =  rot(uv, _Time * -4); 
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
                        float2 uv1 = gv - offset;
                        float randOffset = hash21(id + offset); // random offset
                        
                        float size = frac(randOffset * 345.32);
                        float star = makeStar(uv1 - float2(randOffset, frac(randOffset*34)) + .5, smoothstep(.8, .9, size), .025, 3000); // generate the star
                        
                        float3 color = sin(float3(.2, .3, .9) * frac(randOffset*2345.2)*123.2) *.5 + .5;
                        
                        color *= float3(1, .5, 1+size); // color the star based on size
                        
                        float3 normalized_color = normalize(color);

                        if (normalized_color.r > 0.5) star *= 2*_Bands[1];
                        if (normalized_color.b > 0.5) star *= 2*_Bands[5];
                        if (normalized_color.g > normalized_color.r && normalized_color.g>normalized_color.b) color = float3(1,1,1)*_Bands[7];

                        star*=sin(_Time*50 + randOffset*6.2831)*.5+1; // make the star twinkle
                        
                        col += star * size * color; // add the star to the layer
                    }
                }
                return col;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 col = float3(0, 0, 0);
                float time = _Time; // TODO add time_scalar property
                int band = length(i.uv)*3;
                
                for (float g = 0; g < 1; g+= 1.0 / _Num_Layers)
                {   
                    float depth_pulse = lerp(0,.02,_Bands[band])*_Bands[band];
                    float depth = frac(g + time + depth_pulse);
                    float scale = lerp(_Layer_Zoom, .5, depth);
                    float fade = depth * smoothstep(1, .9, depth);
                    col += starLayer(i.uv * scale + g*453.2) * fade;
                }

                return fixed4(col,1);
            }
            ENDCG
        }
    }
}
