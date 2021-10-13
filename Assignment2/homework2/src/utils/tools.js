function getRotationPrecomputeL(precompute_L, rotationMatrix){
	let precomputeL=precompute_L
	let m33=computeSquareMatrix_3by3(rotationMatrix)
	let m55=computeSquareMatrix_5by5(rotationMatrix)
	let l3=math.matrix([
		[precompute_L[1][0],precompute_L[2][0],precompute_L[3][0]],
		[precompute_L[1][1],precompute_L[2][1],precompute_L[3][1]],
		[precompute_L[1][2],precompute_L[2][2],precompute_L[3][2]]
	])
	let l5=math.matrix([
		[precompute_L[4][0],precompute_L[5][0],precompute_L[6][0],precompute_L[7][0],precompute_L[8][0]],
		[precompute_L[4][1],precompute_L[5][1],precompute_L[6][1],precompute_L[7][1],precompute_L[8][1]],
		[precompute_L[4][2],precompute_L[5][2],precompute_L[6][2],precompute_L[7][2],precompute_L[8][2]]
	])
	let n3=math.multiply(m33,math.transpose(l3))
	let n5=math.multiply(m55,math.transpose(l5))
	
	let colorMat3 = [];
	// for(var i = 0; i<3; i++){
    //     colorMat3[i] = mat3.fromValues( precomputeL[0][i], precomputeL[1][i], precomputeL[2][i],
	// 									precomputeL[3][i], precomputeL[4][i], precomputeL[5][i],
	// 									precomputeL[6][i], precomputeL[7][i], precomputeL[8][i] ); 
	// }
    for(var i = 0; i<3; i++){
        colorMat3[i] = mat3.fromValues( precomputeL[0][i],math.subset(n3, math.index(0, i)), math.subset(n3, math.index(1, i)),
		math.subset(n3, math.index(2, i)), math.subset(n5, math.index(0, i)), math.subset(n5, math.index(1, i)),
		math.subset(n5, math.index(2, i)), math.subset(n5, math.index(3, i)), math.subset(n5, math.index(4, i)) ); 
	}
    return colorMat3;
	//return colorMat3;
	//return result;
}

function computeSquareMatrix_3by3(rotationMatrix){ // 计算方阵SA(-1) 3*3 
	
	// 1、pick ni - {ni}
	let n1 = [1, 0, 0, 0]; let n2 = [0, 0, 1, 0]; let n3 = [0, 1, 0, 0];
	let rotatem=mat4Matrix2mathMatrix(rotationMatrix)
	// 2、{P(ni)} - A  A_inverse
	let ash1=SHEval(n1[0],n1[1],n1[2],3)
	let ash2=SHEval(n2[0],n2[1],n2[2],3)
	let ash3=SHEval(n3[0],n3[1],n3[2],3)
	const a = math.matrix([[ash1[1],ash2[1],ash3[1]],[ash1[2],ash2[2],ash3[2]],[ash1[3],ash2[3],ash3[3]]]);
	let inva=math.inv(a);
	let utilm=math.matrix([n1,n2,n3]);
	let utilmt=math.transpose(utilm)
	let rmn=math.multiply(rotatem,utilmt)
	let ssh1=SHEval(math.subset(rmn, math.index(0, 0)),math.subset(rmn, math.index(1, 0)),math.subset(rmn, math.index(2, 0)),3)
	let ssh2=SHEval(math.subset(rmn, math.index(0, 1)),math.subset(rmn, math.index(1, 1)),math.subset(rmn, math.index(2, 1)),3)
	let ssh3=SHEval(math.subset(rmn, math.index(0, 2)),math.subset(rmn, math.index(1, 2)),math.subset(rmn, math.index(2, 2)),3)
	const s = math.matrix([[ssh1[1],ssh2[1],ssh3[1]],[ssh1[2],ssh2[2],ssh3[2]],[ssh1[3],ssh2[3],ssh3[3]]]);
	const res=math.multiply(s,inva);
	return res;
	// 3、用 R 旋转 ni - {R(ni)}


	// 4、R(ni) SH投影 - S

	// 5、S*A_inverse

}

function computeSquareMatrix_5by5(rotationMatrix){ // 计算方阵SA(-1) 5*5
	
	// 1、pick ni - {ni}
	let k = 1 / math.sqrt(2);
	let n1 = [1, 0, 0, 0]; let n2 = [0, 0, 1, 0]; let n3 = [k, k, 0, 0]; 
	let n4 = [k, 0, k, 0]; let n5 = [0, k, k, 0];
	let rotatem=mat4Matrix2mathMatrix(rotationMatrix)

	let ash1=SHEval(n1[0],n1[1],n1[2],3)
	let ash2=SHEval(n2[0],n2[1],n2[2],3)
	let ash3=SHEval(n3[0],n3[1],n3[2],3)
	let ash4=SHEval(n4[0],n4[1],n4[2],3)
	let ash5=SHEval(n5[0],n5[1],n5[2],3)
	const a = math.matrix([
		[ash1[4],ash2[4],ash3[4],ash4[4],ash5[4]],
		[ash1[5],ash2[5],ash3[5],ash4[5],ash5[5]],
		[ash1[6],ash2[6],ash3[6],ash4[6],ash5[6]],
		[ash1[7],ash2[7],ash3[7],ash4[7],ash5[7]],
		[ash1[8],ash2[8],ash3[8],ash4[8],ash5[8]],
	]);
	let inva=math.inv(a);
	let utilm=math.matrix([n1,n2,n3,n4,n5]);
	let utilmt=math.transpose(utilm)
	let rmn=math.multiply(rotatem,utilmt)
	let ssh1=SHEval(math.subset(rmn, math.index(0, 0)),math.subset(rmn, math.index(1, 0)),math.subset(rmn, math.index(2, 0)),3)
	let ssh2=SHEval(math.subset(rmn, math.index(0, 1)),math.subset(rmn, math.index(1, 1)),math.subset(rmn, math.index(2, 1)),3)
	let ssh3=SHEval(math.subset(rmn, math.index(0, 2)),math.subset(rmn, math.index(1, 2)),math.subset(rmn, math.index(2, 2)),3)
	let ssh4=SHEval(math.subset(rmn, math.index(0, 3)),math.subset(rmn, math.index(1, 3)),math.subset(rmn, math.index(2, 3)),3)
	let ssh5=SHEval(math.subset(rmn, math.index(0, 4)),math.subset(rmn, math.index(1, 4)),math.subset(rmn, math.index(2, 4)),3)
	const s = math.matrix([
		[ssh1[4],ssh2[4],ssh3[4],ssh4[4],ssh5[4]],
		[ssh1[5],ssh2[5],ssh3[5],ssh4[5],ssh5[5]],
		[ssh1[6],ssh2[6],ssh3[6],ssh4[6],ssh5[6]],
		[ssh1[7],ssh2[7],ssh3[7],ssh4[7],ssh5[7]],
		[ssh1[8],ssh2[8],ssh3[8],ssh4[8],ssh5[8]],
	]);
	const res=math.multiply(s,inva);
	return res;
	
	// 2、{P(ni)} - A  A_inverse

	// 3、用 R 旋转 ni - {R(ni)}

	// 4、R(ni) SH投影 - S

	// 5、S*A_inverse

}

function mat4Matrix2mathMatrix(rotationMatrix){

	let mathMatrix = [];
	for(let i = 0; i < 4; i++){
		let r = [];
		for(let j = 0; j < 4; j++){
			r.push(rotationMatrix[i*4+j]);
		}
		mathMatrix.push(r);
	}
	return math.matrix(mathMatrix)

}

function getMat3ValueFromRGB(precomputeL){

    let colorMat3 = [];
    for(var i = 0; i<3; i++){
        colorMat3[i] = mat3.fromValues( precomputeL[0][i], precomputeL[1][i], precomputeL[2][i],
										precomputeL[3][i], precomputeL[4][i], precomputeL[5][i],
										precomputeL[6][i], precomputeL[7][i], precomputeL[8][i] ); 
	}
    return colorMat3;
}