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

    #[Route('/expensive-tools', name: 'api_analytics_expensive_tools', methods: ['GET'])]
    public function expensiveTools(Request $request): JsonResponse
    {
        $limit = max(1, min(100, (int) $request->query->get('limit', 10)));
        $minCost = $request->query->get('min_cost') ? (float) $request->query->get('min_cost') : null;

        $avgCostPerUserCompany = $this->connection->fetchOne(
            'SELECT 
                CASE 
                    WHEN SUM(active_users_count) > 0 
                    THEN ROUND(SUM(monthly_cost) / SUM(active_users_count), 2)
                    ELSE 0
                END
             FROM tools
             WHERE status = "active" AND active_users_count > 0'
        );

        $sql = "
            SELECT 
                id,
                name,
                monthly_cost,
                active_users_count,
                owner_department AS department,
                vendor,
                CASE 
                    WHEN active_users_count > 0 
                    THEN ROUND(monthly_cost / active_users_count, 2)
                    ELSE NULL
                END AS cost_per_user
            FROM tools
            WHERE status = 'active'
        ";

        $params = [];
        if ($minCost !== null) {
            $sql .= " AND monthly_cost >= :minCost";
            $params['minCost'] = $minCost;
        }

        $sql .= " ORDER BY monthly_cost DESC LIMIT " . (int) $limit;

        $tools = $this->connection->fetchAllAssociative($sql, $params);

        $data = [];
        $potentialSavings = 0.0;

        foreach ($tools as $tool) {
            $costPerUser = $tool['cost_per_user'] ? (float) $tool['cost_per_user'] : null;

            $efficiencyRating = 'average';
            if ($costPerUser !== null && $avgCostPerUserCompany > 0) {
                $ratio = $costPerUser / $avgCostPerUserCompany;
                if ($ratio < 0.5) {
                    $efficiencyRating = 'excellent';
                } elseif ($ratio <= 0.8) {
                    $efficiencyRating = 'good';
                } elseif ($ratio <= 1.2) {
                    $efficiencyRating = 'average';
                } else {
                    $efficiencyRating = 'low';
                }
            }

            if ($efficiencyRating === 'low') {
                $potentialSavings += (float) $tool['monthly_cost'];
            }

            $data[] = [
                'id' => (int) $tool['id'],
                'name' => $tool['name'],
                'monthly_cost' => (float) $tool['monthly_cost'],
                'active_users_count' => (int) $tool['active_users_count'],
                'cost_per_user' => $costPerUser,
                'department' => $tool['department'],
                'vendor' => $tool['vendor'],
                'efficiency_rating' => $efficiencyRating,
            ];
        }

        $totalToolsAnalyzed = $this->connection->fetchOne(
            'SELECT COUNT(*) FROM tools WHERE status = "active"'
        );

        return $this->json([
            'data' => $data,
            'analysis' => [
                'total_tools_analyzed' => (int) $totalToolsAnalyzed,
                'avg_cost_per_user_company' => (float) $avgCostPerUserCompany,
                'potential_savings_identified' => round($potentialSavings, 2),
            ],
        ]);
    }

    #[Route('/tools-by-category', name: 'api_analytics_tools_by_category', methods: ['GET'])]
    public function toolsByCategory(): JsonResponse
    {
        $totalCompanyCost = $this->connection->fetchOne(
            'SELECT COALESCE(SUM(monthly_cost), 0) 
             FROM tools 
             WHERE status = "active"'
        );

        $sql = "
            SELECT 
                c.name AS category_name,
                COUNT(t.id) AS tools_count,
                COALESCE(SUM(t.monthly_cost), 0) AS total_cost,
                COALESCE(SUM(t.active_users_count), 0) AS total_users,
                CASE 
                    WHEN :totalCompanyCost > 0 
                    THEN ROUND((SUM(t.monthly_cost) / :totalCompanyCost) * 100, 1)
                    ELSE 0
                END AS percentage_of_budget,
                CASE 
                    WHEN SUM(t.active_users_count) > 0 
                    THEN ROUND(SUM(t.monthly_cost) / SUM(t.active_users_count), 2)
                    ELSE NULL
                END AS average_cost_per_user
            FROM categories c
            LEFT JOIN tools t ON c.id = t.category_id AND t.status = 'active'
            GROUP BY c.id, c.name
            HAVING tools_count > 0
            ORDER BY total_cost DESC
        ";

        $categories = $this->connection->fetchAllAssociative($sql, [
            'totalCompanyCost' => $totalCompanyCost
        ]);

        $data = [];
        $mostEfficientCategory = null;
        $lowestCostPerUser = null;

        foreach ($categories as $cat) {
            $avgCostPerUser = $cat['average_cost_per_user'] ? (float) $cat['average_cost_per_user'] : null;

            if ($avgCostPerUser !== null) {
                if ($lowestCostPerUser === null || $avgCostPerUser < $lowestCostPerUser) {
                    $lowestCostPerUser = $avgCostPerUser;
                    $mostEfficientCategory = $cat['category_name'];

                    if (strcmp($cat['category_name'], $mostEfficientCategory) < 0) {
                        $mostEfficientCategory = $cat['category_name'];
                    }
                }
            }

            $data[] = [
                'category_name' => $cat['category_name'],
                'tools_count' => (int) $cat['tools_count'],
                'total_cost' => (float) $cat['total_cost'],
                'total_users' => (int) $cat['total_users'],
                'percentage_of_budget' => (float) $cat['percentage_of_budget'],
                'average_cost_per_user' => $avgCostPerUser,
            ];
        }

        $mostExpensiveCategory = !empty($data) ? $data[0]['category_name'] : null;

        return $this->json([
            'data' => $data,
            'insights' => [
                'most_expensive_category' => $mostExpensiveCategory,
                'most_efficient_category' => $mostEfficientCategory,
            ],
        ]);
    }

    #[Route('/low-usage-tools', name: 'api_analytics_low_usage_tools', methods: ['GET'])]
    public function lowUsageTools(Request $request): JsonResponse
    {
        $maxUsers = max(0, (int) $request->query->get('max_users', 5));

        $sql = "
            SELECT 
                id,
                name,
                monthly_cost,
                active_users_count,
                owner_department AS department,
                vendor,
                CASE 
                    WHEN active_users_count > 0 
                    THEN ROUND(monthly_cost / active_users_count, 2)
                    ELSE NULL
                END AS cost_per_user
            FROM tools
            WHERE status = 'active' AND active_users_count <= :maxUsers
            ORDER BY monthly_cost DESC
        ";

        $tools = $this->connection->fetchAllAssociative($sql, [
            'maxUsers' => $maxUsers
        ]);

        $data = [];
        $potentialMonthlySavings = 0.0;

        foreach ($tools as $tool) {
            $costPerUser = $tool['cost_per_user'] ? (float) $tool['cost_per_user'] : null;

            $warningLevel = 'low';
            if ($tool['active_users_count'] === 0) {
                $warningLevel = 'high';
            } elseif ($costPerUser !== null) {
                if ($costPerUser > 50) {
                    $warningLevel = 'high';
                } elseif ($costPerUser >= 20) {
                    $warningLevel = 'medium';
                }
            }

            $potentialAction = 'Monitor usage trends';
            if ($warningLevel === 'high') {
                $potentialAction = 'Consider canceling or downgrading';
            } elseif ($warningLevel === 'medium') {
                $potentialAction = 'Review usage and consider optimization';
            }

            if (in_array($warningLevel, ['high', 'medium'])) {
                $potentialMonthlySavings += (float) $tool['monthly_cost'];
            }

            $data[] = [
                'id' => (int) $tool['id'],
                'name' => $tool['name'],
                'monthly_cost' => (float) $tool['monthly_cost'],
                'active_users_count' => (int) $tool['active_users_count'],
                'cost_per_user' => $costPerUser,
                'department' => $tool['department'],
                'vendor' => $tool['vendor'],
                'warning_level' => $warningLevel,
                'potential_action' => $potentialAction,
            ];
        }

        return $this->json([
            'data' => $data,
            'savings_analysis' => [
                'total_underutilized_tools' => count($data),
                'potential_monthly_savings' => round($potentialMonthlySavings, 2),
                'potential_annual_savings' => round($potentialMonthlySavings * 12, 2),
            ],
        ]);
    }
}
