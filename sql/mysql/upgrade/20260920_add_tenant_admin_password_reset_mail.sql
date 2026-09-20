-- 平台端「重置租户超管密码」邮件通知模板
-- 执行前请确认 tenant_mail_account 至少存在一个有效且未删除的发信账号。
-- 本脚本可重复执行；模板已经存在时不会覆盖运营侧对模板内容的自定义。

INSERT INTO tenant_mail_template
    (name, code, account_id, nickname, title, content, params, status, remark, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT
    '租户超管密码重置通知',
    'tenant-reset-admin-password',
    account.id,
    '圣钰SaaS平台',
    '您的圣钰SaaS租户超管密码已重置',
    '<p>您好，{username}：</p><p>租户 <strong>{tenantName}</strong> 的超管密码已由平台管理员重置。</p><p>最新密码：<strong>{password}</strong></p><p>为保障账号安全，请登录后尽快修改密码，且勿将本邮件转发给他人。</p><p>此为系统邮件，请勿直接回复。</p>',
    '["tenantName","username","password"]',
    0,
    '平台管理员重置租户超管密码后自动发送',
    'system',
    NOW(),
    'system',
    NOW(),
    b'0',
    0
FROM tenant_mail_account account
WHERE account.deleted = b'0'
  AND NOT EXISTS (
      SELECT 1 FROM tenant_mail_template template
      WHERE template.code = 'tenant-reset-admin-password'
        AND template.tenant_id = 0
        AND template.deleted = b'0'
  )
ORDER BY account.id
LIMIT 1;
