/**
\page CPFCMakeKnownProblems Known Problems

\section CPFCMakeKnownProblemsSection Known Problems and Workarounds

\subsection CotireQtIncompatibility Problem when using Qt CMAKE_AUTOUIC and CMAKE_AUTORCC in combination with CPF_ENABLE_PRECOMPILED_HEADER

Using CMAKE_AUTOUIC and CMAKE_AUTORCC in combination with cotire can cause compile errors when Qt's autogen targets
are build. In this case you can use the \ref cpfQt5AddUIAndQrcFiles function to fix the problem.

*/