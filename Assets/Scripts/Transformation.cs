using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public abstract class Transformation : MonoBehaviour
{
	public abstract Matrix4x4 Matrix { get; }
}
