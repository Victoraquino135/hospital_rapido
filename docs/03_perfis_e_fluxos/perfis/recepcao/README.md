# Perfil: Recepção

Após o login único, `StaffDashboard` (`frontend/lib/screens/staff_dashboard.dart`) identifica `perfil = recepcao` e apresenta o painel da recepção.

Funcionalidades implementadas:

- resumo diário de agendadas, check-ins, atendimentos, concluídas e ausências;
- seleção de data e filtros por paciente/CPF, especialidade, profissional e status;
- consulta de detalhes com CPF mascarado;
- confirmação de chegada/check-in no dia da consulta;
- registro de não comparecimento;
- atualização da situação da consulta.

A recepção não realiza triagem e não conclui atendimento clínico. As APIs específicas estão sob `/recepcao/*`; algumas operações administrativas de agenda também aceitam recepção onde indicado.
