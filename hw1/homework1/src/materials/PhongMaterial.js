class PhongMaterial extends Material {

    constructor(color, specular, light,light1, translate, scale, vertexShader, fragmentShader) {
        let lightMVP = light.CalcLightMVP(translate, scale);
        let lightMVP1 = light1.CalcLightMVP(translate, scale);
        let lightIntensity = light.mat.GetIntensity();

        super({
            // Phong
            'uSampler': { type: 'texture', value: color },
            'uKs': { type: '3fv', value: specular },
            'uLightIntensity': { type: '3fv', value: lightIntensity },
            // Shadow
            'uShadowMap': { type: 'texture', value: light.fbo },
            'uShadowMap1': { type: 'texture', value: light1.fbo },
            'uLightMVP': { type: 'matrix4fv', value: lightMVP },
            'uLightMVP1': { type: 'matrix4fv', value: lightMVP1 },

        }, [], vertexShader, fragmentShader);
    }
}

async function buildPhongMaterial(color, specular, light,light1 ,translate, scale, vertexPath, fragmentPath) {

    console.log("hello\n")
    let vertexShader = await getShaderString(vertexPath);
    let fragmentShader = await getShaderString(fragmentPath);
    console.log("hello\n")
    return new PhongMaterial(color, specular, light,light1, translate, scale, vertexShader, fragmentShader);

}