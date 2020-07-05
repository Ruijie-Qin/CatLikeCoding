using UnityEngine;

public class PositionTransformation : Transformation
{
    public Vector3 position = Vector3.zero;

    public override Matrix4x4 Matrix
    {
        get
        {
            Matrix4x4 matrix = new Matrix4x4();
            matrix.SetRow(0, new Vector4(1, 0, 0, position.x));
            matrix.SetRow(1, new Vector4(0, 1, 0, position.y));
            matrix.SetRow(2, new Vector4(0, 0, 1, position.z));
            matrix.SetRow(3, new Vector4(0, 0, 0, 1));
            return matrix;
        }
    }
}