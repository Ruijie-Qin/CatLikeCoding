using System;
using System.Collections;
using UnityEngine;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class RoundedCube : MonoBehaviour
{
    public int xSize, ySize, zSize;
    // 三角形是否需要双面
    public bool isDoubleSide = false;
    public int roundness;
    public bool isInnerCube;
    
    private Mesh m_mesh;
    private Vector3[] m_vertices;
    private Vector3[] m_normals;

    private void Awake()
    {
        Generate();
    }

    [ContextMenu("ReGenerate")]
    public void Generate()
    {
        GetComponent<MeshFilter>().mesh = m_mesh = new Mesh();
        m_mesh.name = "Rounded Cube";
        CreateVertices();
        CreateTriangles();
    }

    private void CreateVertices()
    {
        int cornerVertices = 8;
        int edgeVertice = (xSize + ySize + zSize - 3) * 4;
        int faceVertice = ((xSize - 1) * (ySize - 1) + (xSize - 1) * (zSize - 1) + (ySize - 1) * (zSize - 1)) * 2;
        m_vertices = new Vector3[cornerVertices + edgeVertice + faceVertice];
        m_normals = new Vector3[m_vertices.Length];

        int v = 0;
        // 绘制边框
        for (int y = 0; y <= ySize; y++)
        {
            for (int x = 0; x <= xSize; x++)
            {
                SetVertex(v++, x, y, 0);
            }

            for (int z = 1; z <= zSize; z++)
            {
                SetVertex(v++, xSize, y, z);
            }

            for (int x = xSize - 1; x >= 0; x--)
            {
                SetVertex(v++, x, y, zSize);
            }

            for (int z = zSize - 1; z > 0; z--)
            {
                SetVertex(v++, 0, y, z);
            }
        }
        // 绘制顶部
        for (int z = 1; z < zSize; z++)
        {
            for (int x = 1; x < xSize; x++)
            {
                SetVertex(v++, x, ySize, z);
            }
        }
        // 绘制底部
        for (int z = 1; z < zSize; z++)
        {
            for (int x = 1; x < xSize; x++)
            {
                SetVertex(v++, x, 0, z);
            }
        }

        m_mesh.vertices = m_vertices;
        m_mesh.normals = m_normals;
    }

    private void SetVertex(int i, float x, float y, float z)
    {
        Vector3 inner = m_vertices[i] = new Vector3(x, y, z);

        if (inner.x < roundness)
        {
            inner.x = roundness;
        }
        else if (inner.x > xSize - roundness)
        {
            inner.x = xSize - roundness;
        }

        if (inner.y < roundness)
        {
            inner.y = roundness;
        }
        else if (inner.y > ySize - roundness)
        {
            inner.y = ySize - roundness;
        }
        
        if (inner.z < roundness)
        {
            inner.z = roundness;
        }
        else if (inner.z > zSize - roundness)
        {
            inner.z = zSize - roundness;
        }

        m_normals[i] = (m_vertices[i] - inner).normalized;
        if (isInnerCube)
        {
            m_vertices[i] = inner;
        }
        else
        {
            m_vertices[i] = inner + m_normals[i] * roundness;
        }
    }

    private void CreateTriangles()
    {
        // 面数
        int quads = (xSize * ySize + xSize * zSize + ySize * zSize) * 2;
        // 每个面需要2个三角形, 每个三角形需要3个数
        int quadSize = quads * 6 * (isDoubleSide ? 2 : 1); 
        int[] triangles = new int[quadSize];
        int ring = (xSize + zSize) * 2;
        int t = 0, v = 0;

        for (int y = 0; y < ySize; y++, v++)
        {
            for (int q = 0; q < ring - 1; q++, v++)
            {
                t = SetQuad(triangles, t, v, v + 1, v + ring, v + ring + 1, isDoubleSide);
            }
            t = SetQuad(triangles, t, v, v - ring + 1, v + ring, v + 1, isDoubleSide);
        }

        t = CreateTopFace(triangles, t, ring);
        t = CreateBottomFace(triangles, t, ring);
        
        m_mesh.triangles = triangles;
    }

    private int CreateTopFace(int[] triangles, int t, int ring)
    {
        int v = ring * ySize;
        // 绘制顶部的第一行
        for (int x = 0; x < xSize - 1; x++, v++)
        {
            t = SetQuad(triangles, t, v, v + 1, v + ring - 1, v + ring, isDoubleSide);
        }
        t = SetQuad(triangles, t, v, v + 1, v + ring - 1, v + 2, isDoubleSide);
        // 绘制顶部的中间
        int vMin = ring * (ySize + 1) - 1;
        int vMid = vMin + 1;
        int vMax = v + 2;
        for (int z = 1; z < zSize - 1; z++, vMin--, vMid++, vMax++)
        {
            // 绘制中间的第一个
            t = SetQuad(triangles, t, vMin, vMid, vMin - 1, vMid + xSize - 1, isDoubleSide);
            // 绘制中间的中间几个
            for (int x = 1; x < xSize - 1; x++, vMid++)
            {
                t = SetQuad(triangles, t, vMid, vMid + 1, vMid + xSize - 1, vMid + xSize, isDoubleSide);
            }
            // 绘制中间的最后一个
            t = SetQuad(triangles, t, vMid, vMax, vMid + xSize - 1, vMax + 1, isDoubleSide);
        }
        // 绘制顶部的最后一行
        int vTop = vMin - 2;
        // 绘制最后一行的第一个
        t = SetQuad(triangles, t, vMin, vMid, vTop + 1, vTop, isDoubleSide);
        // 绘制最后一行的中间几个
        for (int x = 1; x < xSize - 1; x++, vTop--, vMid++)
        {
            t = SetQuad(triangles, t, vMid, vMid + 1, vTop, vTop - 1, isDoubleSide);
        }
        // 绘制最后一行的最后一个
        t = SetQuad(triangles, t, vMid, vTop - 2, vTop, vTop - 1, isDoubleSide);
        return t;
    }
    
    private int CreateBottomFace(int[] triangles, int t, int ring)
    {
        int vMid = m_vertices.Length - (xSize - 1) * (zSize - 1);
        // 绘制底部第一行的第一个
        t = SetQuad(triangles, t, ring - 1, vMid, 0, 1, isDoubleSide);
        int v = 1;
        // 绘制底部第一行中间几个
        for (int x = 1; x < xSize - 1; x++, v++, vMid++)
        {
            t = SetQuad(triangles, t, vMid, vMid + 1, v, v + 1, isDoubleSide);
        }
        // 绘制底部第一行最后一个
        t = SetQuad(triangles, t, vMid, v + 2, v, v + 1, isDoubleSide);
        
        // 绘制中心的点
        int vMin = ring - 2;
        vMid -= xSize - 2;
        int vMax = v + 2;
        for (int z = 1; z < zSize - 1; z++, vMin--, vMid++, vMax++)
        {
            t = SetQuad(triangles, t, vMin, vMid + xSize - 1, vMin + 1, vMid, isDoubleSide);
            for (int x = 1; x < xSize - 1; x++, vMid++)
            {
                t = SetQuad(triangles, t, vMid + xSize - 1, vMid + xSize, vMid, vMid + 1, isDoubleSide);
            }
            t = SetQuad(triangles, t, vMid + xSize - 1, vMax + 1, vMid, vMax, isDoubleSide);
        }
        
        // 绘制最后一行
        int vTop = vMin - 1;
        t = SetQuad(triangles, t, vTop + 1, vTop, vTop + 2, vMid, isDoubleSide);
        for (int x = 1; x < xSize - 1; x++, vTop--, vMid++)
        {
            t = SetQuad(triangles, t, vTop, vTop - 1, vMid, vMid + 1, isDoubleSide);
        }
        t = SetQuad(triangles, t, vTop, vTop - 1, vMid, vTop - 2, isDoubleSide);
        
        return t;
    }
    private void OnDrawGizmos()
    {
        if (m_vertices == null)
        {
            return;
        }
        
        for (int i = 0; i < m_vertices.Length; i++)
        {
            Gizmos.color = Color.black;
            Gizmos.DrawSphere(transform.TransformPoint(m_vertices[i]), 0.1f);
            Gizmos.color = Color.yellow;
            Gizmos.DrawRay(transform.TransformPoint(m_vertices[i]), m_normals[i]);
        }
    }

    private static int SetQuad(int[] triangles, int i, int v00, int v10, int v01, int v11, bool isDoubleSided)
    {
        triangles[i] = v00;
        triangles[i + 1] = triangles[i + 4] = v01;
        triangles[i + 2] = triangles[i + 3] = v10;
        triangles[i + 5] = v11;
        // 是否需要双面
        if (isDoubleSided)
        {
            i += 6;
            triangles[i] = v00;
            triangles[i + 1] = triangles[i + 4] = v10;
            triangles[i + 2] = triangles[i + 3] = v01;
            triangles[i + 5] = v11;
        }
        return i + 6;
    }
}