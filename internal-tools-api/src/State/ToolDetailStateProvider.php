<?php

namespace App\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use App\Entity\Tool;
use Doctrine\DBAL\Connection;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

class ToolDetailStateProvider implements ProviderInterface
{
    public function __construct(
        private readonly EntityManagerInterface $em,
        private readonly Connection $connection,
    ) {}

    public function provide(Operation $operation, array $uriVariables = [], array $context = []): ?object
    {
        $id = $uriVariables['id'] ?? null;
        if ($id === null) {
            throw new NotFoundHttpException('Tool id is required');
        }

        /** @var Tool|null $tool */
        $tool = $this->em->getRepository(Tool::class)->find($id);
        if (!$tool) {
            throw new NotFoundHttpException(sprintf('Tool with id %s not found', $id));
        }


        $costRow = $this->connection->fetchAssociative(
            'SELECT total_monthly_cost 
             FROM cost_tracking 
             WHERE tool_id = :toolId 
             ORDER BY month_year DESC 
             LIMIT 1',
            ['toolId' => $id]
        );

        $totalMonthlyCost = $costRow ? (float) $costRow['total_monthly_cost'] : null;
        $tool->setTotalMonthlyCost($totalMonthlyCost);


        $usageRow = $this->connection->fetchAssociative(
            'SELECT 
                 COUNT(*) AS total_sessions,
                 AVG(usage_minutes) AS avg_session_minutes
             FROM usage_logs
             WHERE tool_id = :toolId
               AND session_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)',
            ['toolId' => $id]
        );

        $usageMetrics = [
            'last_30_days' => [
                'total_sessions' => isset($usageRow['total_sessions']) ? (int) $usageRow['total_sessions'] : 0,
                'avg_session_minutes' => isset($usageRow['avg_session_minutes']) ? (float) $usageRow['avg_session_minutes'] : 0.0,
            ],
        ];

        $tool->setUsageMetrics($usageMetrics);

        return $tool;
    }
}
