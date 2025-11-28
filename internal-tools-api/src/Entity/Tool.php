<?php

namespace App\Entity;

use ApiPlatform\Doctrine\Orm\Filter\OrderFilter;
use ApiPlatform\Doctrine\Orm\Filter\RangeFilter;
use ApiPlatform\Doctrine\Orm\Filter\SearchFilter;
use ApiPlatform\Metadata\ApiFilter;
use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Post;
use ApiPlatform\Metadata\Put;
use App\Repository\ToolRepository;
use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Doctrine\ORM\Mapping\HasLifecycleCallbacks;
use Doctrine\ORM\Mapping\PrePersist;
use Doctrine\ORM\Mapping\PreUpdate;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity(repositoryClass: ToolRepository::class)]
#[ORM\Table(name: 'tools')]
#[HasLifecycleCallbacks]
#[ApiResource(
    operations: [
        new GetCollection(),
        new Get(provider: 'App\\State\\ToolDetailStateProvider'),
        new Post(),
        new Put()
    ]
)]
#[ApiFilter(
    SearchFilter::class,
    properties: [
        'ownerDepartment' => 'exact',
        'status' => 'exact',
        'category.name' => 'partial',
    ]
)]
#[ApiFilter(
    RangeFilter::class,
    properties: ['monthlyCost']
)]
#[ApiFilter(
    OrderFilter::class,
    properties: ['monthlyCost', 'name', 'createdAt'],
    arguments: ['orderParameterName' => 'sort']
)]
class Tool
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private ?int $id = null;

    #[ORM\Column(length: 100)]
    #[Assert\NotBlank]
    #[Assert\Length(min: 2, max: 100)]
    private ?string $name = null;

    #[ORM\Column(type: Types::TEXT, nullable: true)]
    private ?string $description = null;

    #[ORM\Column(length: 100)]
    #[Assert\NotBlank]
    #[Assert\Length(max: 100)]
    private ?string $vendor = null;

    #[ORM\Column(name: 'website_url', length: 255, nullable: true)]
    #[Assert\Url]
    private ?string $websiteUrl = null;

    #[ORM\Column(name: 'monthly_cost', type: Types::DECIMAL, precision: 10, scale: 2)]
    #[Assert\NotNull]
    #[Assert\PositiveOrZero]
    #[Assert\Type(type: 'numeric')]
    private ?float $monthlyCost = null;

    #[ORM\Column(name: 'active_users_count')]
    #[Assert\PositiveOrZero]
    private ?int $activeUsersCount = 0;

    #[ORM\Column(name: 'owner_department', length: 20)]
    #[Assert\NotBlank]
    #[Assert\Choice(choices: [
        'Engineering',
        'Sales',
        'Marketing',
        'HR',
        'Finance',
        'Operations',
        'Design',
    ])]
    private ?string $ownerDepartment = null;

    #[ORM\Column(name: 'status', length: 20)]
    #[Assert\Choice(choices: ['active', 'deprecated', 'trial'])]
    private ?string $status = 'active';

    #[ORM\Column(name: 'created_at')]
    private ?\DateTimeImmutable $createdAt = null;

    #[ORM\Column(name: 'updated_at')]
    private ?\DateTimeImmutable $updatedAt = null;

    #[ORM\ManyToOne(targetEntity: Category::class, inversedBy: 'tools')]
    #[ORM\JoinColumn(name: 'category_id', referencedColumnName: 'id', nullable: false)]
    #[Assert\NotNull]
    private ?Category $category = null;

    /**
     * Champ calculé : coût mensuel total (depuis cost_tracking)
     */
    private ?float $totalMonthlyCost = null;

    /**
     * Champ calculé : métriques d'usage (depuis usage_logs)
     * Exemple:
     * [
     *   "last_30_days" => [
     *     "total_sessions" => 127,
     *     "avg_session_minutes" => 45
     *   ]
     * ]
     */
    private ?array $usageMetrics = null;

    public function getId(): ?int
    {
        return $this->id;
    }

    public function getName(): ?string
    {
        return $this->name;
    }

    public function setName(string $name): static
    {
        $this->name = $name;

        return $this;
    }

    public function getDescription(): ?string
    {
        return $this->description;
    }

    public function setDescription(?string $description): static
    {
        $this->description = $description;

        return $this;
    }

    public function getVendor(): ?string
    {
        return $this->vendor;
    }

    public function setVendor(string $vendor): static
    {
        $this->vendor = $vendor;

        return $this;
    }

    public function getWebsiteUrl(): ?string
    {
        return $this->websiteUrl;
    }

    public function setWebsiteUrl(?string $websiteUrl): static
    {
        $this->websiteUrl = $websiteUrl;

        return $this;
    }

    public function getMonthlyCost(): ?float
    {
        return $this->monthlyCost;
    }

    public function setMonthlyCost(float $monthlyCost): static
    {
        $this->monthlyCost = $monthlyCost;

        return $this;
    }

    public function getActiveUsersCount(): ?int
    {
        return $this->activeUsersCount;
    }

    public function setActiveUsersCount(int $activeUsersCount): static
    {
        $this->activeUsersCount = $activeUsersCount;

        return $this;
    }

    public function getOwnerDepartment(): ?string
    {
        return $this->ownerDepartment;
    }

    public function setOwnerDepartment(string $ownerDepartment): static
    {
        $this->ownerDepartment = $ownerDepartment;

        return $this;
    }

    public function getStatus(): ?string
    {
        return $this->status;
    }

    public function setStatus(string $status): static
    {
        $this->status = $status;

        return $this;
    }

    public function getCreatedAt(): ?\DateTimeImmutable
    {
        return $this->createdAt;
    }

    public function setCreatedAt(\DateTimeImmutable $createdAt): static
    {
        $this->createdAt = $createdAt;

        return $this;
    }

    public function getUpdatedAt(): ?\DateTimeImmutable
    {
        return $this->updatedAt;
    }

    public function setUpdatedAt(\DateTimeImmutable $updatedAt): static
    {
        $this->updatedAt = $updatedAt;

        return $this;
    }

    public function getCategory(): ?Category
    {
        return $this->category;
    }

    public function setCategory(?Category $category): static
    {
        $this->category = $category;

        return $this;
    }

    public function getTotalMonthlyCost(): ?float
    {
        return $this->totalMonthlyCost;
    }

    public function setTotalMonthlyCost(?float $totalMonthlyCost): static
    {
        $this->totalMonthlyCost = $totalMonthlyCost;

        return $this;
    }

    public function getUsageMetrics(): ?array
    {
        return $this->usageMetrics;
    }

    public function setUsageMetrics(?array $usageMetrics): static
    {
        $this->usageMetrics = $usageMetrics;

        return $this;
    }

    #[PrePersist]
    public function setCreatedAtValue(): void
    {
        if ($this->createdAt === null) {
            $this->createdAt = new \DateTimeImmutable();
        }
        if ($this->updatedAt === null) {
            $this->updatedAt = new \DateTimeImmutable();
        }
    }

    #[PreUpdate]
    public function setUpdatedAtValue(): void
    {
        $this->updatedAt = new \DateTimeImmutable();
    }
}
