<?php

namespace App\Controller;

use Doctrine\DBAL\Connection;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Annotation\Route;

#[Route('/api/analytics')]
class AnalyticsController extends AbstractController
{
    public function __construct(
        private readonly Connection $connection
    ) {}

    #[Route('/department-costs', name: 'api_analytics_department_costs', methods: ['GET'])]
    public function departmentCosts(Request $request): JsonResponse
    {
        $sortBy = $request->query->get('sort_by', 'total_cost');
        $order = strtoupper($request->query->get('order', 'desc'));

        $totalCompanyCost = $this->connection->fetchOne(
            'SELECT COALESCE(SUM(monthly_cost), 0) 
             FROM tools 
             WHERE status = "active"'
        );

        $sql = "
            SELECT 
                owner_department AS department,
                COALESCE(SUM(monthly_cost), 0) AS total_cost,
                COUNT(*) AS tools_count,
                COALESCE(SUM(active_users_count), 0) AS total_users,
                CASE 
                    WHEN COUNT(*) > 0 THEN ROUND(SUM(monthly_cost) / COUNT(*), 2)
                    ELSE 0
                END AS average_cost_per_tool,
                CASE 
                    WHEN :totalCompanyCost > 0 THEN ROUND((SUM(monthly_cost) / :totalCompanyCost) * 100, 1)
                    ELSE 0
                END AS cost_percentage
            FROM tools
            WHERE status = 'active'
            GROUP BY owner_department
        ";

        $validSortFields = ['total_cost', 'department', 'tools_count', 'total_users'];
        $sortBy = in_array($sortBy, $validSortFields) ? $sortBy : 'total_cost';
        $order = in_array($order, ['ASC', 'DESC']) ? $order : 'DESC';

        $sql .= " ORDER BY {$sortBy} {$order}";

        $departments = $this->connection->fetchAllAssociative($sql, [
            'totalCompanyCost' => $totalCompanyCost
        ]);

        $data = array_map(function ($row) {
            return [
                'department' => $row['department'],
                'total_cost' => (float) $row['total_cost'],
                'tools_count' => (int) $row['tools_count'],
                'total_users' => (int) $row['total_users'],
                'average_cost_per_tool' => (float) $row['average_cost_per_tool'],
                'cost_percentage' => (float) $row['cost_percentage'],
            ];
        }, $departments);

        $mostExpensive = null;
        $maxCost = 0;
        foreach ($data as $dept) {
            if ($dept['total_cost'] > $maxCost) {
                $maxCost = $dept['total_cost'];
                $mostExpensive = $dept['department'];
            } elseif ($dept['total_cost'] === $maxCost && $mostExpensive !== null) {
                if (strcmp($dept['department'], $mostExpensive) < 0) {
                    $mostExpensive = $dept['department'];
                }
            }
        }

        return $this->json([
            'data' => $data,
            'summary' => [
                'total_company_cost' => (float) $totalCompanyCost,
                'departments_count' => count($data),
                'most_expensive_department' => $mostExpensive,
            ],
        ]);
    }
}
