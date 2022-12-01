-- Course
# id` VARCHAR(36) NOT NULL,
#   `name` VARCHAR(150) NULL,
#   `course_code` VARCHAR(12) NOT NULL,
#   `affiliation` VARCHAR(36) NOT NULL,
#   `active` BOOLEAN NOT NULL DEFAULT FALSE,
#   `subject` VARCHAR(50) NOT NULL,
#   `license` VARCHAR(75) NULL,
#   `visibility` VARCHAR(10) NOT NULL DEFAULT 'private',

-- create a new course
INSERT INTO course (id, creator, `name`, `course_code`, `subject`)
VALUES (?, ?, ?, ?, ?);

INSERT INTO course_editor (course_id, account_id, `role`)
VALUES (?, ?, 1010);

INSERT INTO private_course (id, color, course_id)
VALUES (?, NULL, ?);

INSERT INTO enrollment (account_id, private_course_id, `role`)
VALUES (?, ?, 1010);

INSERT INTO course_tag (course_id, tag_name)
VALUES (?, ?);


# roles:
#     'creator': 1010,
#     'teacher': 2020,
#     'observer': 3030,
#     'student': 4040

-- update a course

-- first check to see if they have permissions to update a course
SELECT
    *
FROM
    course_editor ce,
    course c,
    `account` a
WHERE
    a.id = ? and
    c.id = ? and
    a.id = ce.account_id and
    c.id = ce.course_id and
    ce.role = 1010 or ce.role = 1011;



UPDATE course
SET name = ?, course_code = ?, subject = ?
WHERE id = ?;

-- add/remove a tag
# first delete all tags and add the new ones
DELETE FROM course_tag
WHERE course_id = ?;

INSERT INTO course_tag (course_id, tag_name)
VALUES (?, ?);


-- get all private courses you're enrolled in
SELECT
    'pc' as type,
    e.status                   as status,
    e.role                     as role,
    c.id                       as id,
    pc.id                      as pcId,
    c.visibility               as visibility,
    c.published                as published,
    pc.active                  as active,
    c.affiliation              as affiliation,
    c.subject                  as subject,
    c.course_code              as code,
    c.license                  as license,
    c.name                     as name,
    c.date_created             as dateCreated,
    c.last_modified            as lastModified,
    JSON_ARRAYAGG(ct.tag_name) as tags,
    enrolled.accounts          as accounts
 FROM account a
          INNER JOIN enrollment e on a.id = e.account_id
          INNER JOIN private_course pc on e.private_course_id = pc.id
          INNER JOIN course c on pc.course_id = c.id
          LEFT JOIN course_tag ct on c.id = ct.course_id
          INNER JOIN (
              SELECT
                  JSON_ARRAYAGG(JSON_OBJECT(
                      'firstName', a.first_name,
                      'lastName', a.last_name,
                      'email', a.email,
                      'role', e.role
                      )) as accounts,
            pc.id as id
        FROM
            private_course pc,
            enrollment e,
            `account` a
        WHERE
            pc.id = e.private_course_id and
            a.id = e.account_id
        GROUP BY pc.id
         ) as enrolled on enrolled.id = pc.id
 WHERE a.id = ?
 GROUP BY pc.id;

select * from private_course INNER JOIN course c on private_course.course_id = c.id;

-- get all accounts enrolled in a private course
SELECT
    a.first_name as firstName,
    a.last_name as lastName,
    a.email as email,
    a.id as accountId,
    e.role as role
FROM
    private_course pc,
    enrollment e,
    `account` a
WHERE
    pc.id = ? and
    pc.id = e.private_course_id and
    a.id = e.account_id;

-- delete a course permanently
DELETE FROM enrollment WHERE private_course_id = ?;

-- get all courses you have access to
SELECT
    'c' as type,
    e.role                     as role,
    c.id                       as id,
    c.visibility               as visibility,
    c.published                as published,
    c.affiliation              as affiliation,
    c.subject                  as subject,
    c.course_code              as code,
    c.license                  as license,
    c.name                     as name,
    c.date_created             as dateCreated,
    c.last_modified            as lastModified,
    JSON_ARRAYAGG(ct.tag_name) as tags,
    editing.accounts           as creators
 FROM account a
          INNER JOIN course_editor e on a.id = e.account_id
          INNER JOIN course c on c.id = e.course_id
          LEFT JOIN course_tag ct on c.id = ct.course_id
          INNER JOIN (
              SELECT
                  JSON_ARRAYAGG(JSON_OBJECT(
                      'firstName', a.first_name,
                      'lastName', a.last_name,
                      'email', a.email,
                      'role', ce.role
                      )) as accounts,
            c.id as id
        FROM
            course c,
            course_editor ce,
            `account` a
        WHERE
            c.id = ce.course_id and
            a.id = ce.account_id
        GROUP BY c.id
         ) as editing on editing.id = c.id
 WHERE a.id = ?
 GROUP BY c.id;

-- update course to show as published (or not)
UPDATE course SET published = ? where course.id = ?;

-- find courses matching name

SELECT
    c.subject as subject,
    c.course_code as code,
    c.last_modified as lastModified,
    c.date_created as dateCreated,
    a.first_name as firstName,
    a.last_name as lastName,
    a.email as email,
    a.home_page_id as homePageId,
    c.license as license,
    c.name as name,
    c.affiliation as affiliation,
    c.id as id,
    c.visibility as visibility,
    JSON_ARRAYAGG(ct.tag_name) as tags
FROM course c
INNER JOIN account a on c.creator = a.id
LEFT JOIN
    course_tag ct on c.id = ct.course_id
WHERE
    (c.course_code like ? or c.name like ?) and
    c.published = true and
    (c.visibility = 'public' or a.id = ?)
GROUP BY c.id;