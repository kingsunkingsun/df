using UnityEngine;
using System.Collections;

public class ConstantMotion : MonoBehaviour {
	
	void FixedUpdate () {
		transform.Rotate(0, 2, 0);
	}

}
