import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite 데이터베이스 헬퍼 클래스
///
/// 싱글톤 패턴을 사용하여 데이터베이스 연결을 관리하고,
/// Users, Spaces, UserSpaceMembers, Tasks 테이블에 대한 CRUD 작업을 제공합니다.
///
/// 확장 가능한 스키마 구조:
/// - Users: 사용자 인증 및 프로필
/// - Spaces: 집/가구 등의 실제 공간
/// - UserSpaceMembers: 사용자와 공간의 N:M 관계 (가족 구성원, 역할)
/// - Tasks: 청소/할일 (배정 대상과 소속 공간 연결)
class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  /// 데이터베이스 인스턴스 getter
  ///
  /// 데이터베이스가 없으면 초기화를 수행합니다.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 데이터베이스 초기화
  ///
  /// 데이터베이스 파일을 생성하고 테이블을 만듭니다.
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'ppodeuk.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// 데이터베이스 테이블 생성
  ///
  /// Users, Spaces, UserSpaceMembers, Tasks 테이블을 생성하고 초기 데이터를 삽입합니다.
  Future<void> _onCreate(Database db, int version) async {
    // Users 테이블 생성 (인증 및 프로필)
    await db.execute('''
      CREATE TABLE Users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE,
        profile_image_url TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Spaces 테이블 생성 (집/가구)
    await db.execute('''
      CREATE TABLE Spaces (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        score INTEGER NOT NULL DEFAULT 100,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // SpaceMemberships 테이블 생성 (N:M 관계, 가족 구성원)
    await db.execute('''
      CREATE TABLE SpaceMemberships (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        space_id INTEGER NOT NULL,
        role TEXT NOT NULL DEFAULT 'member',
        joined_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES Users (id) ON DELETE CASCADE,
        FOREIGN KEY (space_id) REFERENCES Spaces (id) ON DELETE CASCADE,
        UNIQUE(user_id, space_id)
      )
    ''');

    // Tasks 테이블 생성 (청소/할일)
    await db.execute('''
      CREATE TABLE Tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        space_id INTEGER NOT NULL,
        assigned_user_id INTEGER,
        importance INTEGER NOT NULL,
        period INTEGER NOT NULL,
        due_date TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (space_id) REFERENCES Spaces (id) ON DELETE CASCADE,
        FOREIGN KEY (assigned_user_id) REFERENCES Users (id) ON DELETE SET NULL
      )
    ''');

    // MVP 초기 데이터 삽입
    await _insertMVPInitialData(db);
  }

  /// MVP 초기 데이터 삽입
  ///
  /// 앱 최초 실행 시 기본 사용자, 공간, 멤버십을 생성합니다.
  /// MVP에서는 단일 사용자 + 단일 공간 가정으로 시작합니다.
  Future<void> _insertMVPInitialData(Database db) async {
    // 기본 사용자 생성
    final defaultUserId = await db.insert('Users', {
      'name': '사용자',
      'email': null,
      'profile_image_url': null,
    });

    // 기본 공간 생성 (거실, 주방, 욕실)
    final spaceIds = <int>[];
    for (final spaceName in ['거실', '주방', '욕실']) {
      final spaceId = await db.insert('Spaces', {
        'name': spaceName,
        'score': 100,
      });
      spaceIds.add(spaceId);
    }

    // 기본 사용자를 모든 공간의 멤버로 등록
    for (final spaceId in spaceIds) {
      await db.insert('SpaceMemberships', {
        'user_id': defaultUserId,
        'space_id': spaceId,
        'role': 'owner',
      });
    }
  }

  // ============================================================================
  // User CRUD 메소드
  // ============================================================================

  /// 새로운 사용자를 추가합니다.
  ///
  /// [user] Map에는 name, email(선택), profile_image_url(선택) 정보가 포함되어야 합니다.
  /// 생성된 User의 ID를 반환합니다.
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return db.insert('Users', user);
  }

  /// 특정 사용자 정보를 조회합니다.
  ///
  /// [id]에 해당하는 사용자 정보를 반환합니다.
  Future<Map<String, dynamic>?> getUser(int id) async {
    final db = await database;
    final results = await db.query(
      'Users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// 사용자와 같은 공간에 속한 다른 모든 사용자를 조회합니다.
  ///
  /// `userId`는 필수이며, 해당 사용자와 하나 이상의 공통된 공간에 속한
  /// 다른 사용자들의 목록을 반환합니다. 자기 자신은 제외됩니다.
  Future<List<Map<String, dynamic>>> getUsersInSharedSpaces({
    required int userId,
  }) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT DISTINCT u.* FROM Users u
      INNER JOIN SpaceMemberships sm ON u.id = sm.user_id
      WHERE sm.space_id IN (
        SELECT space_id FROM SpaceMemberships WHERE user_id = ?
      ) AND u.id != ?
      ORDER BY u.name ASC
    ''',
      [userId, userId],
    );
  }

  /// 사용자 정보를 업데이트합니다.
  ///
  /// [id]에 해당하는 사용자의 정보를 [user] Map의 내용으로 업데이트합니다.
  /// 업데이트된 행의 개수를 반환합니다.
  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    final db = await database;
    return db.update(
      'Users',
      user,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 사용자를 삭제합니다.
  ///
  /// [id]에 해당하는 사용자를 삭제합니다.
  /// 관련된 멤버십 및 할당된 태스크도 자동으로 처리됩니다.
  Future<int> deleteUser(int id) async {
    final db = await database;
    return db.delete(
      'Users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================================
  // Space CRUD 메소드
  // ============================================================================

  /// 새로운 공간을 추가합니다.
  ///
  /// [space] Map에는 name, score(선택) 정보가 포함되어야 합니다.
  /// 생성된 Space의 ID를 반환합니다.
  Future<int> insertSpace(Map<String, dynamic> space) async {
    final db = await database;
    return db.insert('Spaces', space);
  }

  /// 특정 공간의 점수를 업데이트합니다.
  ///
  /// [id]에 해당하는 공간의 점수를 [score]로 업데이트합니다.
  /// 업데이트된 행의 개수를 반환합니다.
  Future<int> updateSpaceScore(int id, int score) async {
    final db = await database;
    return db.update(
      'Spaces',
      {'score': score},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 공간을 삭제합니다.
  ///
  /// [id]에 해당하는 공간을 삭제합니다.
  /// 관련된 멤버십 및 태스크도 자동으로 삭제됩니다.
  Future<int> deleteSpace(int id) async {
    final db = await database;
    return db.delete(
      'Spaces',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================================
  // SpaceMembership CRUD 메소드
  // ============================================================================

  /// 사용자를 공간의 멤버로 추가합니다.
  ///
  /// [membership] Map에는 user_id, space_id, role(선택) 정보가 포함되어야 합니다.
  /// 생성된 Membership의 ID를 반환합니다.
  Future<int> insertSpaceMembership(Map<String, dynamic> membership) async {
    final db = await database;
    return db.insert('SpaceMemberships', membership);
  }

  /// 특정 공간의 멤버 목록을 조회합니다. (권한 체크)
  ///
  /// `userId`는 필수이며, 해당 사용자가 `spaceId`에 속해 있을 경우에만
  /// 해당 공간의 모든 멤버 목록을 반환합니다. 멤버가 아닐 경우 빈 목록을 반환합니다.
  Future<List<Map<String, dynamic>>> getSpaceMembers({
    required int spaceId,
    required int userId,
  }) async {
    final db = await database;

    // 1. 요청한 사용자가 해당 공간의 멤버인지 확인
    final memberships = await db.query(
      'SpaceMemberships',
      where: 'user_id = ? AND space_id = ?',
      whereArgs: [userId, spaceId],
      limit: 1,
    );

    // 2. 멤버가 아니면 빈 목록을 반환하여 정보 노출 방지
    if (memberships.isEmpty) {
      return [];
    }

    // 3. 멤버가 맞으면 해당 공간의 모든 멤버를 조회
    return db.rawQuery(
      '''
      SELECT u.*, sm.role, sm.joined_at
      FROM Users u
      INNER JOIN SpaceMemberships sm ON u.id = sm.user_id
      WHERE sm.space_id = ?
      ORDER BY sm.joined_at ASC
    ''',
      [spaceId],
    );
  }

  /// 특정 사용자가 속한 모든 공간 목록을 조회합니다. (멤버십 정보 포함)
  ///
  /// `userId`는 필수이며, 해당 사용자가 속한 모든 공간을
  /// 멤버십 정보(`role`, `joined_at`)와 함께 반환합니다.
  Future<List<Map<String, dynamic>>> getSpaces({required int userId}) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT s.*, sm.role, sm.joined_at
      FROM Spaces s
      INNER JOIN SpaceMemberships sm ON s.id = sm.space_id
      WHERE sm.user_id = ?
      ORDER BY sm.joined_at ASC
    ''',
      [userId],
    );
  }

  /// 멤버십을 삭제합니다 (사용자를 공간에서 제거).
  ///
  /// [userId]와 [spaceId]에 해당하는 멤버십을 삭제합니다.
  Future<int> deleteSpaceMembership(int userId, int spaceId) async {
    final db = await database;
    return db.delete(
      'SpaceMemberships',
      where: 'user_id = ? AND space_id = ?',
      whereArgs: [userId, spaceId],
    );
  }

  // ============================================================================
  // Task CRUD 메소드
  // ============================================================================

  /// 새로운 태스크를 추가합니다.
  ///
  /// [task] Map에는 name, space_id, importance, period, assigned_user_id(선택), due_date(선택) 정보가 포함되어야 합니다.
  /// 생성된 Task의 ID를 반환합니다.
  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    return db.insert('Tasks', task);
  }

  /// 사용자가 속한 공간의 태스크 목록을 조회합니다.
  ///
  /// `userId`는 필수이며, 해당 사용자가 멤버로 속한 공간의 태스크만 반환합니다.
  ///
  /// 선택적으로 [spaceId]나 [assignedUserId]를 제공하여 결과를 추가로 필터링할 수 있습니다.
  /// [includeCompleted]가 false이면 완료된 태스크는 제외됩니다.
  Future<List<Map<String, dynamic>>> getTasks({
    required int userId,
    int? spaceId,
    int? assignedUserId,
    bool includeCompleted = true,
  }) async {
    final db = await database;

    final conditions = <String>['sm.user_id = ?'];
    final args = <dynamic>[userId];

    if (spaceId != null) {
      conditions.add('t.space_id = ?');
      args.add(spaceId);
    }
    if (assignedUserId != null) {
      conditions.add('t.assigned_user_id = ?');
      args.add(assignedUserId);
    }
    if (!includeCompleted) {
      conditions.add('t.is_completed = 0');
    }

    final query =
        '''
        SELECT t.* FROM Tasks t
        INNER JOIN SpaceMemberships sm ON t.space_id = sm.space_id
        WHERE ${conditions.join(' AND ')}
        ORDER BY t.due_date ASC
      ''';
    return db.rawQuery(query, args);
  }

  /// 태스크 정보를 업데이트합니다.
  ///
  /// [id]에 해당하는 태스크의 정보를 [task] Map의 내용으로 업데이트합니다.
  /// 업데이트된 행의 개수를 반환합니다.
  Future<int> updateTask(int id, Map<String, dynamic> task) async {
    final db = await database;
    return db.update(
      'Tasks',
      task,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 특정 태스크 정보를 조회합니다.
  Future<Map<String, dynamic>?> getTask(int id) async {
    final db = await database;
    final results = await db.query(
      'Tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// 태스크를 삭제합니다.
  ///
  /// [id]에 해당하는 태스크를 삭제합니다.
  /// 삭제된 행의 개수를 반환합니다.
  Future<int> deleteTask(int id) async {
    final db = await database;
    return db.delete(
      'Tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================================
  // MVP 헬퍼 메소드
  // ============================================================================

  /// MVP용: 기본 사용자의 ID를 반환합니다.
  ///
  /// MVP에서는 단일 사용자를 가정하므로, 첫 번째 사용자의 ID를 반환합니다.
  Future<int> getDefaultUserId() async {
    final db = await database;
    final results = await db.query(
      'Users',
      columns: ['id'],
      limit: 1,
    );
    if (results.isEmpty) {
      throw Exception('기본 사용자가 없습니다. 데이터베이스 초기화를 확인하세요.');
    }
    return results.first['id']! as int;
  }

  /// MVP용: 기본 사용자가 속한 모든 공간을 조회합니다.
  ///
  /// MVP에서는 단일 사용자의 공간만 조회합니다.
  Future<List<Map<String, dynamic>>> getDefaultUserSpaces() async {
    final defaultUserId = await getDefaultUserId();
    return getSpaces(userId: defaultUserId);
  }

  /// MVP용: 기본 사용자가 접근 권한이 있는 모든 태스크를 조회합니다.
  ///
  /// MVP에서는 단일 사용자의 권한 기반으로 태스크를 조회합니다.
  Future<List<Map<String, dynamic>>> getDefaultUserTasks({
    int? assignedUserId,
    bool includeCompleted = true,
  }) async {
    final defaultUserId = await getDefaultUserId();
    return getTasks(
      userId: defaultUserId,
      assignedUserId: assignedUserId,
      includeCompleted: includeCompleted,
    );
  }

  /// 데이터베이스 연결을 닫습니다.
  ///
  /// 앱 종료 시 호출하여 리소스를 정리합니다.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
