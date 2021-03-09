--List edges and the node combinations that can be inserted
WITH Constraints AS (
SELECT object_id AS edge_object_id,
	   CONCAT(QUOTENAME(OBJECT_SCHEMA_NAME(edge_constraints.parent_object_id)), 
			 '.',QUOTENAME(OBJECT_NAME(edge_constraints.parent_object_id))) AS ObjectName,
	   QUOTENAME(name) AS EdgeConstraintName, 
	   delete_referential_action_desc AS DeleteAction
FROM  sys.edge_constraints),
Clauses AS (SELECT object_id AS edge_object_id, 
	   CONCAT(QUOTENAME(OBJECT_SCHEMA_NAME(from_object_id)), '.',QUOTENAME(OBJECT_NAME(from_object_id))) AS FromNode,
	   from_object_id,
	   CONCAT(QUOTENAME(OBJECT_SCHEMA_NAME(to_object_id)), '.',QUOTENAME(OBJECT_NAME(to_object_id))) AS ToNode,
	   to_object_id
FROM   sys.edge_constraint_clauses)
SELECT Constraints.ObjectName, Constraints.EdgeConstraintName, 
       Constraints.DeleteAction,
	   --aggregate allowable connections
	   STRING_AGG(CONCAT('{',Clauses.FromNode,' -> '
                    ,Clauses.ToNode,'}'),'; ') AS AllowedConnections
FROM   constraints
		JOIN Clauses
			ON Clauses.edge_object_id = Constraints.edge_object_id
GROUP BY Constraints.ObjectName, Constraints.EdgeConstraintName, Constraints.DeleteAction
UNION ALL 
--add in any edge that does not have a constraint, and indicate it can be used for any connection
SELECT CONCAT(QUOTENAME(OBJECT_SCHEMA_NAME(object_id)),'.',QUOTENAME(name)) AS ObjectName, 
	   'N\A','N\A', '{Any Node -> Any Node}'
FROM   sys.tables
WHERE  tables.is_edge = 1
 AND   NOT EXISTS (SELECT *
				   FROM   sys.edge_constraints
				   WHERE  edge_constraints.parent_object_id = tables.object_id);
GO


--list nodes and what can be inserted in them both as to and from nodes
WITH UnconstrainedEdgeMix AS (
--output unconstrained nodes as Any Node, rather than the cross product of all node types
SELECT CONCAT(QUOTENAME(OBJECT_SCHEMA_NAME(edges.object_id)), 
			 '.',QUOTENAME(OBJECT_NAME(edges.object_id))) AS EdgeName,
			 CAST(NULL AS int) AS FromNodeId, -CAST(NULL AS int)  AS ToNodeId,
			 'Orphan' AS DeleteAction
FROM   sys.tables AS edges
WHERE  edges.is_edge = 1
  AND  NOT EXISTS (SELECT *
	               FROM  sys.edge_constraints
				   WHERE edges.object_id = edge_constraints.parent_object_id )
), BaseRows AS (
SELECT EdgeName, FromNodeId, ToNodeId, UnconstrainedEdgeMix.DeleteAction
FROM UnconstrainedEdgeMix 
UNION ALL
--add the constrained edges in, with their id and actions
SELECT CONCAT(QUOTENAME(OBJECT_SCHEMA_NAME(edge_constraints.parent_object_id)), 
			 '.',QUOTENAME(OBJECT_NAME(edge_constraints.parent_object_id))) AS EdgeName,
	   from_object_id AS FromNodeId,
	   to_object_id AS ToNodeId,
	   edge_constraints.delete_referential_action_desc AS DeleteAction
FROM   sys.edge_constraint_clauses
		JOIN sys.edge_constraints
			ON edge_constraints.object_id = edge_constraint_clauses.object_id
),
--And the last CTE lets you add filters to the query so you can just look for what Node1 can connect to 
--explicitly (by name) or implicitly (by looking for Any in the node and schema).
FilterFrom AS (
SELECT COALESCE(OBJECT_SCHEMA_NAME(BaseRows.FromNodeId),'Any') AS NodeSchema,
		COALESCE(OBJECT_NAME(BaseRows.FromNodeId),'Any') AS Node, EdgeName, 'From' AS Relationship, DeleteAction
FROM   BaseRows
UNION ALL
SELECT COALESCE(OBJECT_SCHEMA_NAME(BaseRows.FromNodeId),'Any') AS NodeSchema,
	   COALESCE(OBJECT_NAME(BaseRows.FromNodeId),'Any') AS Node, EdgeName, 'To' AS Relationship, DeleteAction
FROM   BaseRows)
SELECT *
FROM   FilterFrom
ORDER BY FilterFrom.NodeSchema, FilterFrom.Node, FilterFrom.Relationship, FilterFrom.EdgeName;
