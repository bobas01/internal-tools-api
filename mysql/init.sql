-- =============================================
-- INTERNAL TOOLS DATABASE - MySQL Version
-- Structure + Seed Data for Technical Test
-- Date Range: 01 May 2025 - 01 August 2025
-- UPDATED FOR PART 2 ANALYTICS SUPPORT
-- =============================================

SET foreign_key_checks = 0;

SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

SET time_zone = '+00:00';

-- =============================================
-- TABLES STRUCTURE
-- =============================================

-- Categories
CREATE TABLE categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    color_hex VARCHAR(7) DEFAULT '#6366f1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tools (UPDATED: active_users_count added for Part 2 analytics)
CREATE TABLE tools (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    vendor VARCHAR(100),
    website_url VARCHAR(255),
    category_id INT NOT NULL,
    monthly_cost DECIMAL(10, 2) NOT NULL,
    active_users_count INT NOT NULL DEFAULT 0,
    owner_department ENUM (
        'Engineering',
        'Sales',
        'Marketing',
        'HR',
        'Finance',
        'Operations',
        'Design'
    ) NOT NULL,
    status ENUM (
        'active',
        'deprecated',
        'trial'
    ) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT
);

-- Users
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    department ENUM (
        'Engineering',
        'Sales',
        'Marketing',
        'HR',
        'Finance',
        'Operations',
        'Design'
    ) NOT NULL,
    role ENUM (
        'employee',
        'manager',
        'admin'
    ) DEFAULT 'employee',
    status ENUM ('active', 'inactive') DEFAULT 'active',
    hire_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- User Tool Access
CREATE TABLE user_tool_access (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    tool_id INT NOT NULL,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    granted_by INT NOT NULL,
    revoked_at TIMESTAMP NULL,
    revoked_by INT NULL,
    status ENUM ('active', 'revoked') DEFAULT 'active',
    UNIQUE KEY unique_user_tool_active (user_id, tool_id, status),
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    FOREIGN KEY (tool_id) REFERENCES tools (id) ON DELETE CASCADE,
    FOREIGN KEY (granted_by) REFERENCES users (id) ON DELETE RESTRICT,
    FOREIGN KEY (revoked_by) REFERENCES users (id) ON DELETE SET NULL
);

-- Access Requests
CREATE TABLE access_requests (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    tool_id INT NOT NULL,
    business_justification TEXT NOT NULL,
    status ENUM (
        'pending',
        'approved',
        'rejected'
    ) DEFAULT 'pending',
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP NULL,
    processed_by INT NULL,
    processing_notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    FOREIGN KEY (tool_id) REFERENCES tools (id) ON DELETE CASCADE,
    FOREIGN KEY (processed_by) REFERENCES users (id) ON DELETE SET NULL
);

-- Usage Logs (Analytics)
CREATE TABLE usage_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    tool_id INT NOT NULL,
    session_date DATE NOT NULL,
    usage_minutes INT DEFAULT 0,
    actions_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    FOREIGN KEY (tool_id) REFERENCES tools (id) ON DELETE CASCADE
);

-- Cost Tracking (Analytics)
CREATE TABLE cost_tracking (
    id INT PRIMARY KEY AUTO_INCREMENT,
    tool_id INT NOT NULL,
    month_year DATE NOT NULL,
    total_monthly_cost DECIMAL(10, 2) NOT NULL,
    active_users_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_tool_month (tool_id, month_year),
    FOREIGN KEY (tool_id) REFERENCES tools (id) ON DELETE CASCADE
);

-- =============================================
-- INDEXES PERFORMANCE
-- =============================================

CREATE INDEX idx_tools_category ON tools (category_id);

CREATE INDEX idx_tools_department ON tools (owner_department);

CREATE INDEX idx_tools_cost_desc ON tools (monthly_cost DESC);

CREATE INDEX idx_tools_status ON tools (status);

CREATE INDEX idx_tools_active_users ON tools (active_users_count DESC);

CREATE INDEX idx_users_department ON users (department);

CREATE INDEX idx_users_status ON users (status);

CREATE INDEX idx_access_user ON user_tool_access (user_id);

CREATE INDEX idx_access_tool ON user_tool_access (tool_id);

CREATE INDEX idx_access_granted_date ON user_tool_access (granted_at);

CREATE INDEX idx_access_status ON user_tool_access (status);

CREATE INDEX idx_requests_status ON access_requests (status);

CREATE INDEX idx_requests_user ON access_requests (user_id);

CREATE INDEX idx_requests_date ON access_requests (requested_at);

CREATE INDEX idx_usage_date_tool ON usage_logs (session_date, tool_id);

CREATE INDEX idx_usage_user_date ON usage_logs (user_id, session_date);

CREATE INDEX idx_cost_month_tool ON cost_tracking (month_year, tool_id);

-- =============================================
-- BUSINESS CONSTRAINTS
-- =============================================

ALTER TABLE tools
ADD CONSTRAINT chk_positive_cost CHECK (monthly_cost >= 0);

ALTER TABLE tools
ADD CONSTRAINT chk_positive_users CHECK (active_users_count >= 0);

ALTER TABLE user_tool_access
ADD CONSTRAINT chk_revoke_after_grant CHECK (
    revoked_at IS NULL
    OR revoked_at >= granted_at
);

ALTER TABLE access_requests
ADD CONSTRAINT chk_process_after_request CHECK (
    processed_at IS NULL
    OR processed_at >= requested_at
);

ALTER TABLE cost_tracking
ADD CONSTRAINT chk_positive_tracking CHECK (
    total_monthly_cost >= 0
    AND active_users_count >= 0
);

-- =============================================
-- SEED DATA - CATEGORIES
-- =============================================

INSERT INTO
    categories (name, description, color_hex)
VALUES (
        'Communication',
        'Messaging and collaboration tools',
        '#10b981'
    ),
    (
        'Development',
        'Development and DevOps tools',
        '#3b82f6'
    ),
    (
        'Design',
        'Design and creative tools',
        '#8b5cf6'
    ),
    (
        'Productivity',
        'Office and productivity suite',
        '#f59e0b'
    ),
    (
        'Analytics',
        'Business Intelligence and analytics',
        '#ef4444'
    ),
    (
        'Security',
        'Security and compliance tools',
        '#6b7280'
    ),
    (
        'Marketing',
        'Marketing and growth tools',
        '#ec4899'
    ),
    (
        'HR',
        'Human resources tools',
        '#14b8a6'
    ),
    (
        'Finance',
        'Finance and accounting tools',
        '#84cc16'
    ),
    (
        'Infrastructure',
        'Cloud and IT infrastructure',
        '#f97316'
    );

-- =============================================
-- SEED DATA - TOOLS (Main tools with active_users_count)
-- =============================================

INSERT INTO
    tools (
        name,
        description,
        vendor,
        website_url,
        category_id,
        monthly_cost,
        active_users_count,
        owner_department,
        status
    )
VALUES
    -- Communication (2 tools)
    (
        'Slack',
        'Team messaging and collaboration platform',
        'Slack Technologies',
        'https://slack.com',
        1,
        8.00,
        25,
        'Engineering',
        'active'
    ),
    (
        'Zoom',
        'Video conferencing and webinars',
        'Zoom Video Communications',
        'https://zoom.us',
        1,
        14.99,
        25,
        'Operations',
        'active'
    ),

-- Development (5 tools)
(
    'GitHub',
    'Version control and collaboration',
    'GitHub Inc.',
    'https://github.com',
    2,
    21.00,
    10,
    'Engineering',
    'active'
),
(
    'Jira',
    'Project management and issue tracking',
    'Atlassian',
    'https://jira.atlassian.com',
    2,
    7.50,
    10,
    'Engineering',
    'active'
),
(
    'Confluence',
    'Team collaboration and documentation',
    'Atlassian',
    'https://confluence.atlassian.com',
    2,
    5.50,
    10,
    'Engineering',
    'active'
),
(
    'Docker Hub',
    'Container registry and tools',
    'Docker Inc.',
    'https://hub.docker.com',
    2,
    5.00,
    7,
    'Engineering',
    'active'
),
(
    'Postman',
    'API development environment',
    'Postman Inc.',
    'https://postman.com',
    2,
    12.00,
    5,
    'Engineering',
    'active'
),

-- Design (2 tools)
(
    'Figma',
    'Collaborative design and prototyping',
    'Figma Inc.',
    'https://figma.com',
    3,
    12.00,
    4,
    'Design',
    'active'
),
(
    'Canva',
    'Graphic design and visual content',
    'Canva Pty Ltd.',
    'https://canva.com',
    3,
    12.99,
    8,
    'Marketing',
    'active'
),

-- Productivity (2 tools)
(
    'Google Workspace',
    'Cloud productivity suite',
    'Google LLC',
    'https://workspace.google.com',
    4,
    6.00,
    25,
    'Operations',
    'active'
),
(
    'Notion',
    'All-in-one workspace',
    'Notion Labs Inc.',
    'https://notion.so',
    4,
    8.00,
    25,
    'Operations',
    'active'
),

-- Analytics (2 tools)
(
    'Google Analytics',
    'Web analytics service',
    'Google LLC',
    'https://analytics.google.com',
    5,
    0.00,
    12,
    'Marketing',
    'active'
),
(
    'Tableau',
    'Business intelligence and analytics',
    'Salesforce',
    'https://tableau.com',
    5,
    70.00,
    3,
    'Finance',
    'active'
),

-- Security (2 tools)
(
    '1Password',
    'Password manager for teams',
    '1Password',
    'https://1password.com',
    6,
    3.99,
    25,
    'Operations',
    'active'
),
(
    'Okta',
    'Identity and access management',
    'Okta Inc.',
    'https://okta.com',
    6,
    2.00,
    25,
    'Operations',
    'active'
),

-- Marketing (2 tools)
(
    'HubSpot',
    'CRM and marketing automation',
    'HubSpot Inc.',
    'https://hubspot.com',
    7,
    45.00,
    6,
    'Marketing',
    'active'
),
(
    'Mailchimp',
    'Email marketing platform',
    'Intuit Mailchimp',
    'https://mailchimp.com',
    7,
    10.00,
    3,
    'Marketing',
    'active'
),

-- HR (1 tool)
(
    'BambooHR',
    'Human resources software',
    'BambooHR LLC',
    'https://bamboohr.com',
    8,
    6.19,
    3,
    'HR',
    'active'
),

-- Finance (1 tool)
(
    'QuickBooks',
    'Accounting software',
    'Intuit Inc.',
    'https://quickbooks.intuit.com',
    9,
    25.00,
    3,
    'Finance',
    'active'
),

-- Infrastructure (1 tool)
(
    'AWS',
    'Cloud computing services',
    'Amazon Web Services',
    'https://aws.amazon.com',
    10,
    150.00,
    2,
    'Engineering',
    'active'
);


-- =============================================
-- SEED DATA - USERS (25 employees across departments)
-- =============================================

INSERT INTO
    users (
        name,
        email,
        department,
        role,
        status,
        hire_date
    )
VALUES
    -- Engineering Team (8 people)
    (
        'Alice Johnson',
        'alice.johnson@company.com',
        'Engineering',
        'manager',
        'active',
        '2024-03-15'
    ),
    (
        'Bob Chen',
        'bob.chen@company.com',
        'Engineering',
        'employee',
        'active',
        '2024-07-22'
    ),
    (
        'Carol Davis',
        'carol.davis@company.com',
        'Engineering',
        'employee',
        'active',
        '2025-01-10'
    ),
    (
        'David Rodriguez',
        'david.rodriguez@company.com',
        'Engineering',
        'employee',
        'active',
        '2024-11-05'
    ),
    (
        'Eva Patel',
        'eva.patel@company.com',
        'Engineering',
        'employee',
        'active',
        '2025-02-18'
    ),
    (
        'Frank Kim',
        'frank.kim@company.com',
        'Engineering',
        'employee',
        'active',
        '2025-04-14'
    ),
    (
        'Grace Li',
        'grace.li@company.com',
        'Engineering',
        'employee',
        'active',
        '2025-06-01'
    ),
    (
        'Henry Wu',
        'henry.wu@company.com',
        'Engineering',
        'employee',
        'active',
        '2025-07-15'
    ),

-- Sales Team (4 people)
(
    'Isabel Garcia',
    'isabel.garcia@company.com',
    'Sales',
    'manager',
    'active',
    '2023-09-12'
),
(
    'Jack Thompson',
    'jack.thompson@company.com',
    'Sales',
    'employee',
    'active',
    '2024-04-28'
),
(
    'Kelly Brown',
    'kelly.brown@company.com',
    'Sales',
    'employee',
    'active',
    '2025-03-07'
),
(
    'Liam Wilson',
    'liam.wilson@company.com',
    'Sales',
    'employee',
    'active',
    '2025-06-15'
),

-- Marketing Team (4 people)
(
    'Maya Anderson',
    'maya.anderson@company.com',
    'Marketing',
    'manager',
    'active',
    '2024-06-08'
),
(
    'Noah Martinez',
    'noah.martinez@company.com',
    'Marketing',
    'employee',
    'active',
    '2024-12-03'
),
(
    'Olivia Singh',
    'olivia.singh@company.com',
    'Marketing',
    'employee',
    'active',
    '2025-05-20'
),
(
    'Paul White',
    'paul.white@company.com',
    'Marketing',
    'employee',
    'active',
    '2025-07-12'
),

-- HR Team (3 people)
(
    'Quinn Taylor',
    'quinn.taylor@company.com',
    'HR',
    'manager',
    'active',
    '2023-11-25'
),
(
    'Rachel Jackson',
    'rachel.jackson@company.com',
    'HR',
    'employee',
    'active',
    '2024-08-16'
),
(
    'Sam Miller',
    'sam.miller@company.com',
    'HR',
    'employee',
    'active',
    '2025-04-30'
),

-- Finance Team (3 people)
(
    'Tina Green',
    'tina.green@company.com',
    'Finance',
    'manager',
    'active',
    '2024-01-20'
),
(
    'Uma Cooper',
    'uma.cooper@company.com',
    'Finance',
    'employee',
    'active',
    '2024-06-14'
),
(
    'Victor Lee',
    'victor.lee@company.com',
    'Finance',
    'employee',
    'active',
    '2025-05-08'
),

-- Operations Team (2 people)
(
    'Wendy Sharma',
    'wendy.sharma@company.com',
    'Operations',
    'manager',
    'active',
    '2024-05-10'
),
(
    'Xavier Wong',
    'xavier.wong@company.com',
    'Operations',
    'employee',
    'active',
    '2025-03-22'
),

-- Design Team (1 person)
(
    'Zoe Clark',
    'zoe.clark@company.com',
    'Design',
    'employee',
    'active',
    '2025-02-18'
),

-- Admin
(
    'Admin User',
    'admin@company.com',
    'Operations',
    'admin',
    'active',
    '2023-01-01'
);

-- =============================================
-- SEED DATA - ADDITIONAL TOOLS FOR ANALYTICS TESTING
-- =============================================

-- Add specialized tools with low usage for testing analytics endpoints
INSERT INTO
    tools (
        name,
        description,
        vendor,
        website_url,
        category_id,
        monthly_cost,
        active_users_count,
        owner_department,
        status
    )
VALUES (
        'Specialized Analytics Pro',
        'Advanced data science platform',
        'DataCorp',
        'https://datacorp.com',
        5,
        159.99,
        1,
        'Marketing',
        'active'
    ),
    (
        'Enterprise Security Suite',
        'Advanced security compliance',
        'SecureCorp',
        'https://securecorp.com',
        6,
        89.99,
        2,
        'Operations',
        'active'
    ),
    (
        'Premium Design Tools',
        'Professional design suite',
        'DesignPro',
        'https://designpro.com',
        3,
        45.00,
        0,
        'Design',
        'active'
    ),
    (
        'Legacy CRM System',
        'Old customer relationship management',
        'OldTech',
        'https://oldtech.com',
        7,
        75.00,
        1,
        'Sales',
        'active'
    );

-- =============================================
-- SEED DATA - USER TOOL ACCESS
-- =============================================

-- Engineering team - comprehensive tooling
INSERT INTO
    user_tool_access (
        user_id,
        tool_id,
        granted_by,
        granted_at
    )
VALUES
    -- Alice Johnson (Engineering Manager) - Full dev stack
    (
        1,
        1,
        26,
        '2025-05-01 09:00:00'
    ), -- Slack
    (
        1,
        2,
        26,
        '2025-05-01 09:00:00'
    ), -- Zoom
    (
        1,
        3,
        26,
        '2025-05-01 09:00:00'
    ), -- GitHub
    (
        1,
        4,
        26,
        '2025-05-01 09:00:00'
    ), -- Jira
    (
        1,
        5,
        26,
        '2025-05-01 09:00:00'
    ), -- Confluence
    (
        1,
        6,
        26,
        '2025-05-01 09:00:00'
    ), -- Docker Hub
    (
        1,
        7,
        26,
        '2025-05-01 09:00:00'
    ), -- Postman
    (
        1,
        10,
        26,
        '2025-05-01 09:00:00'
    ), -- Google Workspace
    (
        1,
        11,
        26,
        '2025-05-01 09:00:00'
    ), -- Notion
    (
        1,
        13,
        26,
        '2025-05-01 09:00:00'
    ), -- 1Password
    (
        1,
        14,
        26,
        '2025-05-01 09:00:00'
    ), -- Okta
    (
        1,
        20,
        26,
        '2025-05-01 09:00:00'
    ), -- AWS

-- Bob Chen (Senior Developer)
(
    2,
    1,
    1,
    '2025-05-05 09:00:00'
), -- Slack
(
    2,
    2,
    1,
    '2025-05-05 09:00:00'
), -- Zoom
(
    2,
    3,
    1,
    '2025-05-05 09:00:00'
), -- GitHub
(
    2,
    4,
    1,
    '2025-05-05 09:00:00'
), -- Jira
(
    2,
    5,
    1,
    '2025-05-05 09:00:00'
), -- Confluence
(
    2,
    6,
    1,
    '2025-05-05 09:00:00'
), -- Docker Hub
(
    2,
    7,
    1,
    '2025-05-05 09:00:00'
), -- Postman
(
    2,
    10,
    1,
    '2025-05-05 09:00:00'
), -- Google Workspace
(
    2,
    11,
    1,
    '2025-05-05 09:00:00'
), -- Notion
(
    2,
    13,
    1,
    '2025-05-05 09:00:00'
), -- 1Password
(
    2,
    20,
    1,
    '2025-05-10 10:00:00'
), -- AWS

-- Carol Davis (Developer)
(
    3,
    1,
    1,
    '2025-05-12 09:00:00'
),
(
    3,
    2,
    1,
    '2025-05-12 09:00:00'
),
(
    3,
    3,
    1,
    '2025-05-12 09:00:00'
),
(
    3,
    4,
    1,
    '2025-05-12 09:00:00'
),
(
    3,
    5,
    1,
    '2025-05-12 09:00:00'
),
(
    3,
    6,
    1,
    '2025-05-12 09:00:00'
),
(
    3,
    7,
    1,
    '2025-05-12 09:00:00'
),
(
    3,
    10,
    1,
    '2025-05-12 09:00:00'
),
(
    3,
    11,
    1,
    '2025-05-12 09:00:00'
),
(
    3,
    13,
    1,
    '2025-05-12 09:00:00'
),

-- David Rodriguez (Developer)
(
    4,
    1,
    1,
    '2025-05-15 09:00:00'
),
(
    4,
    2,
    1,
    '2025-05-15 09:00:00'
),
(
    4,
    3,
    1,
    '2025-05-15 09:00:00'
),
(
    4,
    4,
    1,
    '2025-05-15 09:00:00'
),
(
    4,
    5,
    1,
    '2025-05-15 09:00:00'
),
(
    4,
    6,
    1,
    '2025-05-15 09:00:00'
),
(
    4,
    7,
    1,
    '2025-05-15 09:00:00'
),
(
    4,
    10,
    1,
    '2025-05-15 09:00:00'
),
(
    4,
    11,
    1,
    '2025-05-15 09:00:00'
),
(
    4,
    13,
    1,
    '2025-05-15 09:00:00'
),

-- Eva Patel (Developer)
(
    5,
    1,
    1,
    '2025-05-18 09:00:00'
),
(
    5,
    2,
    1,
    '2025-05-18 09:00:00'
),
(
    5,
    3,
    1,
    '2025-05-18 09:00:00'
),
(
    5,
    4,
    1,
    '2025-05-18 09:00:00'
),
(
    5,
    5,
    1,
    '2025-05-18 09:00:00'
),
(
    5,
    6,
    1,
    '2025-05-18 09:00:00'
),
(
    5,
    7,
    1,
    '2025-05-18 09:00:00'
),
(
    5,
    10,
    1,
    '2025-05-18 09:00:00'
),
(
    5,
    11,
    1,
    '2025-05-18 09:00:00'
),
(
    5,
    13,
    1,
    '2025-05-18 09:00:00'
),

-- Frank Kim (Junior Developer)
(
    6,
    1,
    1,
    '2025-05-20 09:00:00'
),
(
    6,
    2,
    1,
    '2025-05-20 09:00:00'
),
(
    6,
    3,
    1,
    '2025-05-20 09:00:00'
),
(
    6,
    4,
    1,
    '2025-05-20 09:00:00'
),
(
    6,
    5,
    1,
    '2025-05-20 09:00:00'
),
(
    6,
    10,
    1,
    '2025-05-20 09:00:00'
),
(
    6,
    11,
    1,
    '2025-05-20 09:00:00'
),
(
    6,
    13,
    1,
    '2025-05-20 09:00:00'
),

-- Grace Li (Junior Developer)
(
    7,
    1,
    1,
    '2025-06-02 09:00:00'
),
(
    7,
    2,
    1,
    '2025-06-02 09:00:00'
),
(
    7,
    3,
    1,
    '2025-06-02 09:00:00'
),
(
    7,
    4,
    1,
    '2025-06-02 09:00:00'
),
(
    7,
    5,
    1,
    '2025-06-02 09:00:00'
),
(
    7,
    10,
    1,
    '2025-06-02 09:00:00'
),
(
    7,
    11,
    1,
    '2025-06-02 09:00:00'
),
(
    7,
    13,
    1,
    '2025-06-02 09:00:00'
),

-- Henry Wu (Junior Developer)
(
    8,
    1,
    1,
    '2025-07-16 09:00:00'
),
(
    8,
    2,
    1,
    '2025-07-16 09:00:00'
),
(
    8,
    3,
    1,
    '2025-07-16 09:00:00'
),
(
    8,
    4,
    1,
    '2025-07-16 09:00:00'
),
(
    8,
    5,
    1,
    '2025-07-16 09:00:00'
),
(
    8,
    10,
    1,
    '2025-07-16 09:00:00'
),
(
    8,
    11,
    1,
    '2025-07-16 09:00:00'
),
(
    8,
    13,
    1,
    '2025-07-16 09:00:00'
),

-- Sales Team
-- Isabel Garcia (Sales Manager)
(
    9,
    1,
    26,
    '2025-05-01 10:00:00'
),
(
    9,
    2,
    26,
    '2025-05-01 10:00:00'
),
(
    9,
    10,
    26,
    '2025-05-01 10:00:00'
),
(
    9,
    11,
    26,
    '2025-05-01 10:00:00'
),
(
    9,
    13,
    26,
    '2025-05-01 10:00:00'
),
(
    9,
    15,
    26,
    '2025-05-01 10:00:00'
),
(
    9,
    12,
    26,
    '2025-05-01 10:00:00'
),

-- Jack Thompson, Kelly Brown, Liam Wilson (Sales Reps)
(
    10,
    1,
    9,
    '2025-05-05 10:00:00'
),
(
    10,
    2,
    9,
    '2025-05-05 10:00:00'
),
(
    10,
    10,
    9,
    '2025-05-05 10:00:00'
),
(
    10,
    11,
    9,
    '2025-05-05 10:00:00'
),
(
    10,
    13,
    9,
    '2025-05-05 10:00:00'
),
(
    10,
    15,
    9,
    '2025-05-05 10:00:00'
),
(
    11,
    1,
    9,
    '2025-05-08 10:00:00'
),
(
    11,
    2,
    9,
    '2025-05-08 10:00:00'
),
(
    11,
    10,
    9,
    '2025-05-08 10:00:00'
),
(
    11,
    11,
    9,
    '2025-05-08 10:00:00'
),
(
    11,
    13,
    9,
    '2025-05-08 10:00:00'
),
(
    11,
    15,
    9,
    '2025-05-08 10:00:00'
),
(
    12,
    1,
    9,
    '2025-06-16 10:00:00'
),
(
    12,
    2,
    9,
    '2025-06-16 10:00:00'
),
(
    12,
    10,
    9,
    '2025-06-16 10:00:00'
),
(
    12,
    11,
    9,
    '2025-06-16 10:00:00'
),
(
    12,
    13,
    9,
    '2025-06-16 10:00:00'
),
(
    12,
    15,
    9,
    '2025-06-16 10:00:00'
),

-- Marketing Team
-- Maya Anderson (Marketing Manager) - Full marketing stack
(
    13,
    1,
    26,
    '2025-05-01 11:00:00'
),
(
    13,
    2,
    26,
    '2025-05-01 11:00:00'
),
(
    13,
    8,
    26,
    '2025-05-01 11:00:00'
),
(
    13,
    9,
    26,
    '2025-05-01 11:00:00'
),
(
    13,
    10,
    26,
    '2025-05-01 11:00:00'
),
(
    13,
    11,
    26,
    '2025-05-01 11:00:00'
),
(
    13,
    12,
    26,
    '2025-05-01 11:00:00'
),
(
    13,
    13,
    26,
    '2025-05-01 11:00:00'
),
(
    13,
    15,
    26,
    '2025-05-01 11:00:00'
),
(
    13,
    16,
    26,
    '2025-05-01 11:00:00'
),

-- Noah Martinez (Marketing)
(
    14,
    1,
    13,
    '2025-05-05 11:00:00'
),
(
    14,
    2,
    13,
    '2025-05-05 11:00:00'
),
(
    14,
    9,
    13,
    '2025-05-05 11:00:00'
),
(
    14,
    10,
    13,
    '2025-05-05 11:00:00'
),
(
    14,
    11,
    13,
    '2025-05-05 11:00:00'
),
(
    14,
    12,
    13,
    '2025-05-05 11:00:00'
),
(
    14,
    13,
    13,
    '2025-05-05 11:00:00'
),
(
    14,
    15,
    13,
    '2025-05-05 11:00:00'
),
(
    14,
    16,
    13,
    '2025-05-05 11:00:00'
),

-- Olivia Singh (Marketing)
(
    15,
    1,
    13,
    '2025-05-21 11:00:00'
),
(
    15,
    2,
    13,
    '2025-05-21 11:00:00'
),
(
    15,
    9,
    13,
    '2025-05-21 11:00:00'
),
(
    15,
    10,
    13,
    '2025-05-21 11:00:00'
),
(
    15,
    11,
    13,
    '2025-05-21 11:00:00'
),
(
    15,
    12,
    13,
    '2025-05-21 11:00:00'
),
(
    15,
    13,
    13,
    '2025-05-21 11:00:00'
),
(
    15,
    15,
    13,
    '2025-05-21 11:00:00'
),
(
    15,
    16,
    13,
    '2025-05-21 11:00:00'
),

-- Paul White (Marketing)
(
    16,
    1,
    13,
    '2025-07-13 11:00:00'
),
(
    16,
    2,
    13,
    '2025-07-13 11:00:00'
),
(
    16,
    9,
    13,
    '2025-07-13 11:00:00'
),
(
    16,
    10,
    13,
    '2025-07-13 11:00:00'
),
(
    16,
    11,
    13,
    '2025-07-13 11:00:00'
),
(
    16,
    12,
    13,
    '2025-07-13 11:00:00'
),
(
    16,
    13,
    13,
    '2025-07-13 11:00:00'
),
(
    16,
    15,
    13,
    '2025-07-13 11:00:00'
),
(
    16,
    16,
    13,
    '2025-07-13 11:00:00'
),

-- HR Team
-- Quinn Taylor (HR Manager)
(
    17,
    1,
    26,
    '2025-05-01 12:00:00'
),
(
    17,
    2,
    26,
    '2025-05-01 12:00:00'
),
(
    17,
    9,
    26,
    '2025-05-01 12:00:00'
),
(
    17,
    10,
    26,
    '2025-05-01 12:00:00'
),
(
    17,
    11,
    26,
    '2025-05-01 12:00:00'
),
(
    17,
    13,
    26,
    '2025-05-01 12:00:00'
),
(
    17,
    17,
    26,
    '2025-05-01 12:00:00'
),

-- Rachel Jackson, Sam Miller (HR team)
(
    18,
    1,
    17,
    '2025-05-05 12:00:00'
),
(
    18,
    2,
    17,
    '2025-05-05 12:00:00'
),
(
    18,
    10,
    17,
    '2025-05-05 12:00:00'
),
(
    18,
    11,
    17,
    '2025-05-05 12:00:00'
),
(
    18,
    13,
    17,
    '2025-05-05 12:00:00'
),
(
    18,
    17,
    17,
    '2025-05-05 12:00:00'
),
(
    19,
    1,
    17,
    '2025-05-01 12:00:00'
),
(
    19,
    2,
    17,
    '2025-05-01 12:00:00'
),
(
    19,
    10,
    17,
    '2025-05-01 12:00:00'
),
(
    19,
    11,
    17,
    '2025-05-01 12:00:00'
),
(
    19,
    13,
    17,
    '2025-05-01 12:00:00'
),
(
    19,
    17,
    17,
    '2025-05-01 12:00:00'
),

-- Finance Team
-- Tina Green (Finance Manager)
(
    20,
    1,
    26,
    '2025-05-01 13:00:00'
),
(
    20,
    2,
    26,
    '2025-05-01 13:00:00'
),
(
    20,
    10,
    26,
    '2025-05-01 13:00:00'
),
(
    20,
    11,
    26,
    '2025-05-01 13:00:00'
),
(
    20,
    12,
    26,
    '2025-05-01 13:00:00'
),
(
    20,
    13,
    26,
    '2025-05-01 13:00:00'
),
(
    20,
    18,
    26,
    '2025-05-01 13:00:00'
),
(
    20,
    19,
    26,
    '2025-05-01 13:00:00'
),

-- Uma Cooper, Victor Lee (Finance team)
(
    21,
    1,
    20,
    '2025-05-05 13:00:00'
),
(
    21,
    2,
    20,
    '2025-05-05 13:00:00'
),
(
    21,
    10,
    20,
    '2025-05-05 13:00:00'
),
(
    21,
    11,
    20,
    '2025-05-05 13:00:00'
),
(
    21,
    13,
    20,
    '2025-05-05 13:00:00'
),
(
    21,
    18,
    20,
    '2025-05-05 13:00:00'
),
(
    21,
    19,
    20,
    '2025-05-05 13:00:00'
),
(
    22,
    1,
    20,
    '2025-05-09 13:00:00'
),
(
    22,
    2,
    20,
    '2025-05-09 13:00:00'
),
(
    22,
    10,
    20,
    '2025-05-09 13:00:00'
),
(
    22,
    11,
    20,
    '2025-05-09 13:00:00'
),
(
    22,
    13,
    20,
    '2025-05-09 13:00:00'
),
(
    22,
    18,
    20,
    '2025-05-09 13:00:00'
),

-- Operations Team
-- Wendy Sharma (Operations Manager)
(
    23,
    1,
    26,
    '2025-05-01 14:00:00'
),
(
    23,
    2,
    26,
    '2025-05-01 14:00:00'
),
(
    23,
    9,
    26,
    '2025-05-01 14:00:00'
),
(
    23,
    10,
    26,
    '2025-05-01 14:00:00'
),
(
    23,
    11,
    26,
    '2025-05-01 14:00:00'
),
(
    23,
    12,
    26,
    '2025-05-01 14:00:00'
),
(
    23,
    13,
    26,
    '2025-05-01 14:00:00'
),
(
    23,
    14,
    26,
    '2025-05-01 14:00:00'
),

-- Xavier Wong (Operations)
(
    24,
    1,
    23,
    '2025-05-05 14:00:00'
),
(
    24,
    2,
    23,
    '2025-05-05 14:00:00'
),
(
    24,
    10,
    23,
    '2025-05-05 14:00:00'
),
(
    24,
    11,
    23,
    '2025-05-05 14:00:00'
),
(
    24,
    13,
    23,
    '2025-05-05 14:00:00'
),
(
    24,
    14,
    23,
    '2025-05-05 14:00:00'
),

-- Design Team
-- Zoe Clark (Designer)
(
    25,
    1,
    26,
    '2025-05-01 15:00:00'
),
(
    25,
    2,
    26,
    '2025-05-01 15:00:00'
),
(
    25,
    8,
    26,
    '2025-05-01 15:00:00'
),
(
    25,
    9,
    26,
    '2025-05-01 15:00:00'
),
(
    25,
    10,
    26,
    '2025-05-01 15:00:00'
),
(
    25,
    11,
    26,
    '2025-05-01 15:00:00'
),
(
    25,
    13,
    26,
    '2025-05-01 15:00:00'
),

-- Special access for low-usage tools testing
(
    13,
    21,
    26,
    '2025-07-01 10:00:00'
), -- Maya has Specialized Analytics Pro
(
    23,
    22,
    26,
    '2025-07-01 11:00:00'
), -- Wendy has Enterprise Security Suite  
(
    24,
    22,
    26,
    '2025-07-01 11:00:00'
), -- Xavier has Enterprise Security Suite
(
    10,
    24,
    26,
    '2025-07-01 12:00:00'
);
-- Jack has Legacy CRM System

-- Admin User - Full access to all tools
INSERT INTO
    user_tool_access (
        user_id,
        tool_id,
        granted_by,
        granted_at
    )
SELECT 26, id, 26, '2025-05-01 08:00:00'
FROM tools
WHERE
    status = 'active';

-- =============================================
-- SEED DATA - ACCESS REQUESTS
-- =============================================

INSERT INTO
    access_requests (
        user_id,
        tool_id,
        business_justification,
        status,
        requested_at,
        processed_at,
        processed_by,
        processing_notes
    )
VALUES
    -- Approved requests
    (
        3,
        20,
        'Need AWS access for new microservices deployment',
        'approved',
        '2025-05-15 09:00:00',
        '2025-05-15 14:00:00',
        1,
        'Approved - DevOps responsibility'
    ),
    (
        14,
        8,
        'Require Figma for marketing design collaboration',
        'approved',
        '2025-05-22 10:30:00',
        '2025-05-22 16:00:00',
        13,
        'Approved for design collaboration'
    ),
    (
        21,
        12,
        'Need Google Analytics for financial KPI tracking',
        'approved',
        '2025-06-10 11:00:00',
        '2025-06-12 09:00:00',
        20,
        'Approved - Budget reporting requirement'
    ),

-- Pending requests
(
    8,
    20,
    'Need AWS access for learning and development',
    'pending',
    '2025-07-25 14:00:00',
    NULL,
    NULL,
    NULL
),
(
    15,
    8,
    'Request Figma access for campaign mockups',
    'pending',
    '2025-07-28 09:30:00',
    NULL,
    NULL,
    NULL
),
(
    22,
    19,
    'Need Tableau access for advanced financial analytics',
    'pending',
    '2025-07-30 10:15:00',
    NULL,
    NULL,
    NULL
),
(
    12,
    12,
    'Request Google Analytics for sales funnel analysis',
    'pending',
    '2025-07-31 11:00:00',
    NULL,
    NULL,
    NULL
),

-- Rejected requests
(
    10,
    19,
    'Request Tableau access for sales reporting',
    'rejected',
    '2025-06-20 11:00:00',
    '2025-06-22 15:00:00',
    9,
    'Use HubSpot analytics for sales metrics instead'
),
(
    16,
    20,
    'Need AWS access for personal learning project',
    'rejected',
    '2025-07-05 14:30:00',
    '2025-07-06 10:00:00',
    13,
    'AWS access limited to Engineering team only'
);

-- =============================================
-- SEED DATA - USAGE LOGS (Sample May-July 2025)
-- =============================================

INSERT INTO
    usage_logs (
        user_id,
        tool_id,
        session_date,
        usage_minutes,
        actions_count
    )
VALUES
    -- Slack usage (high frequency)
    (1, 1, '2025-05-01', 240, 45),
    (2, 1, '2025-05-01', 180, 32),
    (3, 1, '2025-05-01', 195, 28),
    (9, 1, '2025-05-01', 220, 38),
    (13, 1, '2025-05-01', 200, 35),
    (17, 1, '2025-05-01', 185, 30),
    (20, 1, '2025-05-01', 175, 28),
    (23, 1, '2025-05-01', 190, 33),

-- GitHub usage (Engineering team)
(1, 3, '2025-05-01', 120, 15),
(2, 3, '2025-05-01', 180, 22),
(3, 3, '2025-05-01', 165, 20),
(4, 3, '2025-05-01', 145, 18),
(5, 3, '2025-05-01', 135, 16),

-- HubSpot usage (Sales/Marketing)
(9, 15, '2025-05-01', 200, 30),
(10, 15, '2025-05-01', 180, 25),
(11, 15, '2025-05-01', 165, 22),
(12, 15, '2025-05-01', 140, 18),
(13, 15, '2025-05-01', 190, 28),
(14, 15, '2025-05-01', 160, 22),

-- Tableau usage (Finance - expensive tool)
(20, 19, '2025-05-01', 120, 10),
(21, 19, '2025-05-01', 90, 8),
(22, 19, '2025-05-01', 75, 6),

-- BambooHR usage (HR team)
(17, 17, '2025-05-01', 150, 18),
(18, 17, '2025-05-01', 120, 15),
(19, 17, '2025-05-01', 90, 12),

-- Low usage tools (for testing low-usage analytics)
(13, 21, '2025-07-01', 45, 5), -- Specialized Analytics Pro - 1 user, high cost
(23, 22, '2025-07-01', 30, 3),
(24, 22, '2025-07-01', 25, 2), -- Enterprise Security Suite - 2 users
(10, 24, '2025-07-01', 15, 1), -- Legacy CRM System - 1 user

-- Additional sampling across June-July
(1, 1, '2025-06-01', 235, 42),
(1, 1, '2025-07-01', 220, 38),
(20, 19, '2025-06-01', 115, 9),
(20, 19, '2025-07-01', 110, 8),
(13, 15, '2025-06-01', 195, 29),
(13, 15, '2025-07-01', 185, 26);

-- =============================================
-- SEED DATA - COST TRACKING (May-July 2025)
-- =============================================

INSERT INTO
    cost_tracking (
        tool_id,
        month_year,
        total_monthly_cost,
        active_users_count
    )
VALUES
    -- May 2025 costs
    (1, '2025-05-01', 200.00, 25),
    (2, '2025-05-01', 374.75, 25),
    (3, '2025-05-01', 210.00, 10),
    (4, '2025-05-01', 75.00, 10),
    (5, '2025-05-01', 55.00, 10),
    (6, '2025-05-01', 35.00, 7),
    (7, '2025-05-01', 60.00, 5),
    (8, '2025-05-01', 48.00, 4),
    (9, '2025-05-01', 103.92, 8),
    (10, '2025-05-01', 150.00, 25),
    (11, '2025-05-01', 200.00, 25),
    (12, '2025-05-01', 0.00, 12),
    (13, '2025-05-01', 99.75, 25),
    (14, '2025-05-01', 50.00, 25),
    (15, '2025-05-01', 270.00, 6),
    (16, '2025-05-01', 30.00, 3),
    (17, '2025-05-01', 18.57, 3),
    (18, '2025-05-01', 75.00, 3),
    (19, '2025-05-01', 210.00, 3),
    (20, '2025-05-01', 300.00, 2),

-- New tools costs (for analytics testing)
(21, '2025-07-01', 159.99, 1), -- Specialized Analytics Pro - high cost, 1 user
(22, '2025-07-01', 89.99, 2), -- Enterprise Security Suite - medium cost, 2 users  
(23, '2025-07-01', 45.00, 0), -- Premium Design Tools - cost with 0 users
(24, '2025-07-01', 75.00, 1), -- Legacy CRM System - high cost, 1 user

-- June 2025 costs (evolution)
(1, '2025-06-01', 208.00, 26),
(2, '2025-06-01', 389.74, 26),
(19, '2025-06-01', 210.00, 3),
(20, '2025-06-01', 300.00, 2),

-- July 2025 costs (more evolution)
(1, '2025-07-01', 216.00, 27),
(2, '2025-07-01', 404.73, 27),
(19, '2025-07-01', 210.00, 3),
(20, '2025-07-01', 300.00, 2);

SET foreign_key_checks = 1;

