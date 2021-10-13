class PrtMaterial extends Material {

    constructor(color, specular, light, translate, scale, vertexShader, fragmentShader) {
        let lightIntensity = light.mat.GetIntensity();
        let lmat33=getMat3ValueFromRGB(precomputeL[guiParams.envmapId])
        super({
            // Phong
            'uKs': { type: '3fv', value: specular },
            'uLightRadiance': { type: '3fv', value: lightIntensity },
            'aPrecomputeLR':{type:'matrix3fv',value:lmat33[0]},
            'aPrecomputeLG':{type:'matrix3fv',value:lmat33[1]},
            'aPrecomputeLB':{type:'matrix3fv',value:lmat33[2]},
            'uSampler': { type: 'texture', value: color },
        }, 
        ['aPrecomputeLT'], 
        vertexShader, fragmentShader, null);
    }
}

async function buildPrtMaterial(color, specular, light, translate, scale, vertexPath, fragmentPath) {


    let vertexShader = await getShaderString(vertexPath);
    let fragmentShader = await getShaderString(fragmentPath);

    return new PrtMaterial(color, specular, light, translate, scale, vertexShader, fragmentShader);

}