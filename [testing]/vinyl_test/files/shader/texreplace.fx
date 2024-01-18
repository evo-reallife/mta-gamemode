//-- Declare the textures. These are set using dxSetShaderValue( shader, "Tex0", texture )
texture Tex0;
texture Tex1;

//-- Very simple technique
technique simple
{
    pass P0
    {
        //-- Set up texture stage 0
        Texture[0] = Tex0;
        ColorOp[0] = SelectArg1;
        ColorArg1[0] = Texture;
        AlphaOp[0] = SelectArg1;
        AlphaArg1[0] = Texture;

        //-- Disable texture stage 1
        ColorOp[1] = Disable;
        AlphaOp[1] = Disable;
    }
}

