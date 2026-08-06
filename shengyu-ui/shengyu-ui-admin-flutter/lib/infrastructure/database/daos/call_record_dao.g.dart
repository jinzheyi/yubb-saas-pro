// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_record_dao.dart';

// ignore_for_file: type=lint
mixin _$CallRecordDaoMixin on DatabaseAccessor<ImDatabase> {
  $CallRecordsTable get callRecords => attachedDatabase.callRecords;
  CallRecordDaoManager get managers => CallRecordDaoManager(this);
}

class CallRecordDaoManager {
  final _$CallRecordDaoMixin _db;
  CallRecordDaoManager(this._db);
  $$CallRecordsTableTableManager get callRecords =>
      $$CallRecordsTableTableManager(_db.attachedDatabase, _db.callRecords);
}
