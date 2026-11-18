/// 跨层结果类型：数据层不把裸异常抛到 UI。
///
/// UI 读 [Ok] / [Err] 自行渲染，错误消息存在 [AppError.message] 里，可以直接展示。
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error);
  final AppError error;
}

/// 面向用户的错误：message 必须是可以直接显示的文案，cause 留作调试。
class AppError {
  const AppError(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
